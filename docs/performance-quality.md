# ForgeMedia Performance and Quality Target

## User target

ForgeMedia must remain fast and responsive while processing very large media, including videos up to approximately five hours, and produce clear, high-quality outputs.

## Practical interpretation

This is a product target, not a promise of magic. The app should be engineered so long media does not cause UI lag, crashes, lost progress, or unusable outputs. Quality should be validated with objective checks and presets, not vague claims like “Hollywood-grade.”

## Architecture requirements

### Keep the UI lightweight

- `MenuBarExtra` must never perform media work.
- Heavy jobs run in background workers or an XPC/helper process.
- UI receives progress events, cancellation state, and final result only.
- Menu bar remains clickable during transcription, conversion, upscaling, or export.

### Process media in chunks

For long videos:

- Probe duration, bitrate, codec, rotation, HDR metadata, and audio layout before starting.
- Split work into resumable segments where possible.
- Write intermediate outputs to a project cache.
- Preserve partial outputs for retry.
- Avoid loading a five-hour video fully into memory.

### Use the right engine per task

- AVFoundation for native timeline composition and fast Apple Silicon paths.
- FFmpeg for containers, filters, subtitles, burn-in, probing, and legacy formats.
- Whisper.cpp for offline transcription with cached transcripts.
- Core ML / MLX / Metal only after model quality and throughput are benchmarked.

### Quality gates

Each output job should record:

- Input checksum.
- Output checksum.
- Duration.
- Resolution.
- Codec.
- Bitrate.
- Audio sample rate/channel layout.
- Subtitle/caption status.
- Processing preset.
- Engine version.
- Known limitations.

For restoration/upscaling/dubbing jobs, add objective checks where possible:

- PSNR/SSIM/VMAF-style comparison against source when applicable.
- Audio loudness check.
- Subtitle timing sanity check.
- Frame count/duration mismatch detection.

## Performance strategy

### Fast path

Use native Apple paths first:

1. Same-container stitching with AVFoundation.
2. Hardware-accelerated decode/encode where supported.
3. Native Audio/Video composition.
4. Background worker queue with concurrency limits.

### Heavy path

Use controlled external engines:

1. FFmpeg process runner with progress parsing.
2. Whisper.cpp batch processing.
3. Optional Python/Core ML worker for AI-heavy tasks.
4. Clear cancellation and cleanup.

### Concurrency limits

The app should not let every job max out the machine.

Default policy:

- One media export at a time unless the user enables parallel processing.
- Transcription can run while export is idle.
- AI upscaling should reserve GPU/ANE resources and throttle other GPU-heavy work.
- Menu bar UI always gets priority.

## Five-hour video checklist

Before accepting a job:

- [ ] File is readable and not zero-byte.
- [ ] Duration and streams are detected.
- [ ] Estimated output size is calculated.
- [ ] Available disk space is checked.
- [ ] User is warned if output may exceed available space.
- [ ] Progress reporting is enabled.
- [ ] Cancellation is available.
- [ ] Partial output can be recovered or safely deleted.

During processing:

- [ ] UI remains responsive.
- [ ] Progress updates are throttled to avoid UI churn.
- [ ] Logs are streamed without blocking.
- [ ] Temporary files are named and cleaned predictably.
- [ ] Long jobs survive app relaunch when possible.

After processing:

- [ ] Output opens and duration matches expected range.
- [ ] Audio/video sync is checked.
- [ ] Subtitles/captions align if generated.
- [ ] Output checksum is stored.
- [ ] Temporary files are cleaned unless retained for recovery.

## Quality positioning

ForgeMedia should say:

- “High-quality local processing”
- “Clear output with quality checks”
- “Optimized for long media workflows”

Avoid unsupported claims such as:

- “Perfect quality”
- “Hollywood-grade”
- “Instant five-hour processing”
- “Guaranteed Dolby Vision output”

Those become valid only after benchmarks and licensed tooling support them.

## Engineering rule

Speed comes from architecture:

- Native shell.
- Background workers.
- Chunked processing.
- Resumable jobs.
- Hardware acceleration where supported.
- Strict quality gates.
- No UI blocking.
- No unnecessary refactors.
