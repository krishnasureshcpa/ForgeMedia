#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional

try:
    from tqdm import tqdm
except Exception:
    def tqdm(iterable, **kwargs):
        return iterable

VIDEO_EXTENSIONS = {".mp4", ".mov", ".mkv", ".avi", ".m4v", ".webm"}


@dataclass
class PipelineConfig:
    source: Path
    destination: Path
    target_language: str
    whisper_model: str
    lip_sync_tool: str
    wav2lip_repo: Optional[Path]
    musetalk_repo: Optional[Path]
    ffmpeg_bin: str
    keep_temp: bool
    single_file: Optional[Path]
    quality_profile: str


class PipelineError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(msg, flush=True)


def run_command(cmd: List[str], cwd: Optional[Path] = None) -> None:
    pretty = " ".join(cmd)
    log(f"[CMD] {pretty}")
    proc = subprocess.Popen(
        cmd,
        cwd=str(cwd) if cwd else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    captured: List[str] = []
    assert proc.stdout is not None
    for line in proc.stdout:
        text = line.rstrip("\n")
        captured.append(text)
        if text:
            log(f"[TOOL] {text}")

    code = proc.wait()
    if code != 0:
        details = "\n".join(captured[-40:])
        raise PipelineError(f"Command failed ({code}): {pretty}\n{details}")


def require_any_command(candidates: List[str], label: str) -> str:
    for cmd in candidates:
        if shutil.which(cmd):
            return cmd
    raise PipelineError(f"Missing required command for {label}: tried {', '.join(candidates)}")


def collect_videos(root: Path) -> List[Path]:
    videos: List[Path] = []
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS:
            videos.append(path)
    return sorted(videos)


def collect_single_video(source_root: Path, target_file: Path) -> List[Path]:
    resolved = target_file.expanduser().resolve()
    if not resolved.exists() or not resolved.is_file():
        raise PipelineError(f"single-file path does not exist: {resolved}")
    if resolved.suffix.lower() not in VIDEO_EXTENSIONS:
        raise PipelineError(f"single-file is not a supported video extension: {resolved}")
    try:
        resolved.relative_to(source_root)
    except ValueError as exc:
        raise PipelineError(f"single-file must be inside source folder: {resolved}") from exc
    return [resolved]


def ensure_tree(source_root: Path, destination_root: Path, video_path: Path) -> Path:
    rel = video_path.relative_to(source_root)
    out_dir = destination_root / rel.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir


def stage_whisperx(config: PipelineConfig, video_path: Path, work_dir: Path) -> Path:
    log(f"[STEP] WhisperX diarization + SRT: {video_path}")
    whisperx_exec = require_any_command(["whisperx"], "WhisperX")
    output_dir = work_dir / "whisperx"
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        whisperx_exec,
        str(video_path),
        "--model", config.whisper_model,
        "--language", "auto",
        "--diarize",
        "--output_format", "srt",
        "--output_dir", str(output_dir),
    ]
    run_command(cmd)

    candidates = sorted(output_dir.glob("*.srt"))
    if not candidates:
        raise PipelineError("WhisperX did not produce an .srt subtitle file")
    return candidates[0]


def stage_open_dubbing(config: PipelineConfig, video_path: Path, work_dir: Path) -> Path:
    log(f"[STEP] open_dubbing translation + dubbing: {video_path}")
    open_dubbing_exec = require_any_command(["open-dubbing", "open_dubbing"], "open_dubbing")
    output_dir = work_dir / "open_dubbing"
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        open_dubbing_exec,
        "--input_file", str(video_path),
        "--target_language", config.target_language,
        "--output_dir", str(output_dir),
    ]
    run_command(cmd)

    dubbed_candidates = sorted(output_dir.rglob("*.wav")) + sorted(output_dir.rglob("*.mp3")) + sorted(output_dir.rglob("*.m4a"))
    if not dubbed_candidates:
        raise PipelineError("open_dubbing did not produce a dubbed audio track")
    return dubbed_candidates[0]


def stage_lipsync(config: PipelineConfig, original_video: Path, dubbed_audio: Path, work_dir: Path) -> Path:
    if config.lip_sync_tool == "none":
        return original_video

    output_video = work_dir / "lipsynced.mp4"

    if config.lip_sync_tool == "wav2lip":
        log(f"[STEP] Wav2Lip visual lip-sync: {original_video}")
        if config.wav2lip_repo and (config.wav2lip_repo / "inference.py").exists():
            cmd = [
                "python3", "inference.py",
                "--face", str(original_video),
                "--audio", str(dubbed_audio),
                "--outfile", str(output_video),
            ]
            run_command(cmd, cwd=config.wav2lip_repo)
        else:
            wav2lip_exec = require_any_command(["wav2lip-infer"], "Wav2Lip executable")
            run_command([wav2lip_exec, "--face", str(original_video), "--audio", str(dubbed_audio), "--outfile", str(output_video)])

    elif config.lip_sync_tool == "musetalk":
        log(f"[STEP] MuseTalk visual lip-sync: {original_video}")
        if config.musetalk_repo and (config.musetalk_repo / "inference.py").exists():
            cmd = [
                "python3", "inference.py",
                "--video", str(original_video),
                "--audio", str(dubbed_audio),
                "--output", str(output_video),
            ]
            run_command(cmd, cwd=config.musetalk_repo)
        else:
            musetalk_exec = require_any_command(["musetalk-infer"], "MuseTalk executable")
            run_command([musetalk_exec, "--video", str(original_video), "--audio", str(dubbed_audio), "--output", str(output_video)])
    else:
        raise PipelineError(f"Unsupported lip sync tool: {config.lip_sync_tool}")

    if not output_video.exists():
        raise PipelineError("Lip-sync stage did not produce output video")
    return output_video


def stage_mux_and_burn(config: PipelineConfig, lipsynced_video: Path, dubbed_audio: Path, subtitle_srt: Path, final_output: Path) -> None:
    log(f"[STEP] FFmpeg multiplex + burn subtitles: {final_output}")
    final_output.parent.mkdir(parents=True, exist_ok=True)

    if config.quality_profile == "fast":
        video_preset = "veryfast"
        crf = "23"
        audio_bitrate = "160k"
    else:
        video_preset = "medium"
        crf = "18"
        audio_bitrate = "192k"

    cmd = [
        config.ffmpeg_bin,
        "-y",
        "-i", str(lipsynced_video),
        "-i", str(dubbed_audio),
        "-map", "0:v:0",
        "-map", "1:a:0",
        "-vf", f"subtitles={subtitle_srt}",
        "-c:v", "libx264",
        "-preset", video_preset,
        "-crf", crf,
        "-c:a", "aac",
        "-b:a", audio_bitrate,
        "-shortest",
        str(final_output),
    ]
    run_command(cmd)


def process_one(config: PipelineConfig, video_path: Path) -> dict:
    rel = video_path.relative_to(config.source)
    out_dir = ensure_tree(config.source, config.destination, video_path)
    final_output = out_dir / f"{video_path.stem}.mp4"
    subtitle_out = out_dir / f"{video_path.stem}.srt"

    work_dir = config.destination / ".pipeline_tmp" / rel.parent / video_path.stem
    work_dir.mkdir(parents=True, exist_ok=True)

    log(f"[FILE] Processing: {rel}")

    subtitle = stage_whisperx(config, video_path, work_dir)
    shutil.copy2(subtitle, subtitle_out)

    dubbed_audio = stage_open_dubbing(config, video_path, work_dir)
    lipsynced_video = stage_lipsync(config, video_path, dubbed_audio, work_dir)
    stage_mux_and_burn(config, lipsynced_video, dubbed_audio, subtitle_out, final_output)

    if not config.keep_temp:
        shutil.rmtree(work_dir, ignore_errors=True)

    log(f"[DONE] {rel} -> {final_output.relative_to(config.destination)}")
    return {
        "source": str(video_path),
        "output": str(final_output),
        "subtitle": str(subtitle_out),
        "status": "ok",
    }


def parse_args() -> PipelineConfig:
    parser = argparse.ArgumentParser(description="Recursive open-source video dubbing pipeline")
    parser.add_argument("--source", required=True, help="Source folder containing videos")
    parser.add_argument("--destination", required=True, help="Destination folder for mirrored outputs")
    parser.add_argument("--target-language", default="en")
    parser.add_argument("--whisper-model", default="large-v3")
    parser.add_argument("--lip-sync-tool", choices=["musetalk", "wav2lip", "none"], default="musetalk")
    parser.add_argument("--wav2lip-repo", default=None)
    parser.add_argument("--musetalk-repo", default=None)
    parser.add_argument("--ffmpeg-bin", default=shutil.which("ffmpeg") or "/opt/homebrew/bin/ffmpeg")
    parser.add_argument("--keep-temp", action="store_true")
    parser.add_argument("--single-file", default=None, help="Process only one file inside --source")
    parser.add_argument("--quality-profile", choices=["fast", "quality"], default="fast")
    args = parser.parse_args()

    source = Path(args.source).expanduser().resolve()
    destination = Path(args.destination).expanduser().resolve()
    if not source.exists() or not source.is_dir():
        raise SystemExit(f"Source directory does not exist: {source}")
    destination.mkdir(parents=True, exist_ok=True)

    return PipelineConfig(
        source=source,
        destination=destination,
        target_language=args.target_language,
        whisper_model=args.whisper_model,
        lip_sync_tool=args.lip_sync_tool,
        wav2lip_repo=Path(args.wav2lip_repo).expanduser().resolve() if args.wav2lip_repo else None,
        musetalk_repo=Path(args.musetalk_repo).expanduser().resolve() if args.musetalk_repo else None,
        ffmpeg_bin=args.ffmpeg_bin,
        keep_temp=args.keep_temp,
        single_file=Path(args.single_file).expanduser().resolve() if args.single_file else None,
        quality_profile=args.quality_profile,
    )


def main() -> int:
    config = parse_args()
    try:
        require_any_command([config.ffmpeg_bin], "FFmpeg") if os.path.sep not in config.ffmpeg_bin else None
        if os.path.sep in config.ffmpeg_bin and not Path(config.ffmpeg_bin).exists():
            raise PipelineError(f"FFmpeg binary not found: {config.ffmpeg_bin}")
    except Exception as exc:
        log(f"[FATAL] dependency check failed: {exc}")
        return 2

    files = collect_single_video(config.source, config.single_file) if config.single_file else collect_videos(config.source)
    if not files:
        log(f"[FATAL] no supported video files found under: {config.source}")
        return 1

    log(f"[INFO] Found {len(files)} video files")
    results = []
    errors = []

    for video_path in tqdm(files, desc="ForgeMedia batch", unit="file"):
        try:
            result = process_one(config, video_path)
            results.append(result)
        except Exception as exc:
            rel = video_path.relative_to(config.source)
            err = {
                "source": str(video_path),
                "status": "failed",
                "error": str(exc),
                "traceback": traceback.format_exc(),
            }
            errors.append(err)
            log(f"[ERROR] {rel}: {exc}")
            continue

    summary_path = config.destination / "pipeline_summary.json"
    with summary_path.open("w", encoding="utf-8") as f:
        json.dump({"processed": results, "failed": errors}, f, indent=2)

    log(f"[INFO] Summary written: {summary_path}")
    log(f"[INFO] Success: {len(results)} | Failed: {len(errors)}")
    return 0 if not errors else 3


if __name__ == "__main__":
    sys.exit(main())
