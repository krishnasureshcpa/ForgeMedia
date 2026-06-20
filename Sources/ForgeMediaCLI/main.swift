import Foundation
import ForgeMediaDomain
import ForgeMediaMedia
import Darwin

struct CLIConfig {
    let mode: String
    let input: String
    let presetID: String
    let recursive: Bool
}

@main
struct ForgeMediaCLI {
    static func main() async {
        do {
            let config = try parseArguments(Array(CommandLine.arguments.dropFirst()))
            let engine = resolveEngine()
            let preset = resolvePreset(id: config.presetID)
            let inputs = try resolveInputs(mode: config.mode, input: config.input, recursive: config.recursive)

            if inputs.isEmpty {
                print("[forge-media-cli] No valid media files found.")
                Foundation.exit(1)
            }

            print("[forge-media-cli] mode=\(config.mode) files=\(inputs.count) preset=\(preset.id)")

            var failed = 0
            let renderer = TUIProgressRenderer()
            for (index, url) in inputs.enumerated() {
                let title = url.lastPathComponent
                let outputURL = defaultOutputURL(for: url, preset: preset)
                let job = JobRecord(
                    title: title,
                    sourceURL: url,
                    outputURL: outputURL,
                    presetID: preset.id,
                    phase: .idle,
                    progressLabel: "Queued",
                    privacyMode: .privacyOn
                )

                renderer.startFile(index: index + 1, total: inputs.count, title: title)

                do {
                    let output = try await engine.run(job, preset: preset) { progress in
                        renderer.update(phase: progress.phase, fraction: progress.fraction, label: progress.label)
                    }
                    renderer.complete(outputPath: output.url.path)
                } catch {
                    failed += 1
                    renderer.fail(message: error.localizedDescription)
                }
            }

            if failed > 0 {
                print("[forge-media-cli] Completed with failures: \(failed)")
                Foundation.exit(2)
            }

            print("[forge-media-cli] Completed successfully")
            Foundation.exit(0)
        } catch {
            print("[forge-media-cli] Error: \(error.localizedDescription)")
            print(usage)
            Foundation.exit(1)
        }
    }

    static func resolveEngine() -> ProcessingEngine {
        let candidates: [(ffmpeg: String, ffprobe: String)] = [
            ("/opt/homebrew/bin/ffmpeg", "/opt/homebrew/bin/ffprobe"),
            ("/usr/local/bin/ffmpeg", "/usr/local/bin/ffprobe"),
            ("/usr/bin/ffmpeg", "/usr/bin/ffprobe")
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate.ffmpeg) {
            return CompositeProcessingEngine(
                defaultEngine: FFmpegProcessRunner(
                    ffmpegPath: candidate.ffmpeg,
                    ffprobePath: FileManager.default.isExecutableFile(atPath: candidate.ffprobe) ? candidate.ffprobe : nil
                ),
                openDubbingEngine: OpenDubbingBatchEngine()
            )
        }

        return FakeProcessingEngine()
    }

    static func resolvePreset(id: String) -> MediaPreset {
        MediaPreset.builtIn.first(where: { $0.id == id }) ?? MediaPreset.builtIn.first(where: { $0.id == "convert_h264" })!
    }

    static func defaultOutputURL(for input: URL, preset: MediaPreset) -> URL {
        let ext = preset.outputContainer.isEmpty ? "mp4" : preset.outputContainer
        let dir = input.deletingLastPathComponent()
        // Strip all extensions (handles double-extension files like .mp4.mp4), then
        // add a preset suffix so the output never collides with the input path.
        var stem = input.lastPathComponent
        while stem.contains(".") {
            stem = URL(fileURLWithPath: stem).deletingPathExtension().lastPathComponent
        }
        return dir.appendingPathComponent("\(stem)_\(preset.id)").appendingPathExtension(ext)
    }

    static func resolveInputs(mode: String, input: String, recursive: Bool) throws -> [URL] {
        let path = URL(fileURLWithPath: input)
        let fm = FileManager.default

        switch mode {
        case "single":
            guard isVideo(path) else { return [] }
            return [path]

        case "multi":
            let parts = input.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            return parts.map { URL(fileURLWithPath: $0) }.filter(isVideo)

        case "folder":
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path.path, isDirectory: &isDir), isDir.boolValue else {
                return []
            }

            guard let enumerator = fm.enumerator(
                at: path,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) else {
                return []
            }

            var files: [URL] = []
            for case let url as URL in enumerator where isVideo(url) {
                files.append(url)
            }
            return files.sorted { $0.path < $1.path }

        default:
            return []
        }
    }

    static func isVideo(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "mkv", "avi", "m4v", "webm"].contains(ext)
    }

    static func parseArguments(_ args: [String]) throws -> CLIConfig {
        if args.isEmpty {
            return try interactiveConfig()
        }

        var mode = ""
        var input = ""
        var presetID = "convert_h264"
        var recursive = true

        var index = 0
        while index < args.count {
            let arg = args[index]
            switch arg {
            case "--mode":
                index += 1
                if index < args.count { mode = args[index] }
            case "--input":
                index += 1
                if index < args.count { input = args[index] }
            case "--preset":
                index += 1
                if index < args.count { presetID = args[index] }
            case "--recursive":
                recursive = true
            case "--no-recursive":
                recursive = false
            case "-h", "--help":
                throw CLIError.helpRequested
            default:
                if arg.hasPrefix("--") {
                    // unknown flag ignored for forward compatibility
                } else if input.isEmpty {
                    input = arg
                }
            }
            index += 1
        }

        if input.isEmpty {
            throw CLIError.missingInput
        }

        if mode.isEmpty {
            mode = inferMode(from: input)
        }

        guard ["single", "multi", "folder"].contains(mode) else {
            throw CLIError.invalidMode
        }

        return CLIConfig(mode: mode, input: input, presetID: presetID, recursive: recursive)
    }

    static func interactiveConfig() throws -> CLIConfig {
        print("[forge-media-cli] Interactive mode")

        let selection = chooseModeWithMenu()
        let input: String
        let mode: String
        var recursive = true

        switch selection {
        case "1":
            mode = "single"
            input = prompt("Video file path")
        case "2":
            mode = "multi"
            input = prompt("Comma-separated video file paths")
        case "3":
            mode = "folder"
            recursive = true
            input = prompt("Folder path")
        case "4":
            mode = "folder"
            recursive = false
            input = prompt("Folder path")
        default:
            throw CLIError.invalidMode
        }

        guard !input.isEmpty else { throw CLIError.missingInput }

        printPresetCatalog()
        let presetInput = prompt("Preset [convert_h264]")
        let presetID = presetInput.isEmpty ? "convert_h264" : presetInput

        return CLIConfig(mode: mode, input: input, presetID: presetID, recursive: recursive)
    }

    static func chooseModeWithMenu() -> String {
        while true {
            print("\nChoose action:")
            print("  1) Process single video")
            print("  2) Process selected videos (comma-separated)")
            print("  3) Process all videos in folder (recursive)")
            print("  4) Process all videos in folder (non-recursive)")
            print("  p) Show presets")
            print("  h) Show help")
            print("  q) Quit")

            let value = prompt("Selection [1]")
            let choice = value.isEmpty ? "1" : value.lowercased()

            switch choice {
            case "1", "2", "3", "4":
                return choice
            case "p":
                printPresetCatalog()
            case "h":
                print(usage)
            case "q":
                Foundation.exit(0)
            default:
                print("Invalid selection: \(choice)")
            }
        }
    }

    static func printPresetCatalog() {
        print("\nAvailable presets:")
        for preset in MediaPreset.builtIn {
            print("  - \(preset.id): \(preset.name)")
        }
    }

    static func inferMode(from input: String) -> String {
        if input.contains(",") {
            return "multi"
        }

        let url = URL(fileURLWithPath: input)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return "folder"
        }

        return "single"
    }

    static func prompt(_ text: String) -> String {
        print("\(text): ", terminator: "")
        fflush(stdout)
        return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

final class TUIProgressRenderer: @unchecked Sendable {
    private let lock = NSLock()
    private let isInteractiveTTY: Bool
    private let stages = ["preparing", "probing", "planning", "running", "validating"]
    private var stageProgress: [String: Double] = [:]
    private var title = ""
    private var fileIndex = 0
    private var fileTotal = 0
    private var statusLabel = ""
    private var spinnerFrame = 0
    private var inFullScreen = false

    init() {
        self.isInteractiveTTY = isatty(STDOUT_FILENO) != 0
        for stage in stages {
            stageProgress[stage] = 0.0
        }

        if isInteractiveTTY {
            enterFullScreen()
        }
    }

    deinit {
        if isInteractiveTTY {
            leaveFullScreen()
        }
    }

    func startFile(index: Int, total: Int, title: String) {
        lock.lock()
        defer { lock.unlock() }

        self.fileIndex = index
        self.fileTotal = total
        self.title = title
        self.statusLabel = "Queued"
        self.spinnerFrame = 0
        for stage in stages {
            stageProgress[stage] = 0.0
        }

        if isInteractiveTTY {
            renderLocked()
        }
    }

    func update(phase: JobPhase, fraction: Double, label: String) {
        lock.lock()
        defer { lock.unlock() }

        statusLabel = label
        advanceStageProgress(phase: phase, fraction: fraction)

        if isInteractiveTTY {
            spinnerFrame = (spinnerFrame + 1) % spinnerGlyphs.count
            renderLocked()
        }
    }

    func complete(outputPath: String) {
        lock.lock()
        defer { lock.unlock() }

        for stage in stages {
            stageProgress[stage] = 1.0
        }
        statusLabel = "Completed"

        if isInteractiveTTY {
            spinnerFrame = 0
            renderLocked(finalStatePrefix: "DONE")
        }
        print("[forge-media-cli] [\(fileIndex)/\(fileTotal)] DONE -> \(outputPath)")
    }

    func fail(message: String) {
        lock.lock()
        defer { lock.unlock() }

        statusLabel = "Failed: \(message)"
        if isInteractiveTTY {
            renderLocked(finalStatePrefix: "FAIL")
        }
        print("[forge-media-cli] [\(fileIndex)/\(fileTotal)] FAIL: \(message)")
    }

    private func advanceStageProgress(phase: JobPhase, fraction: Double) {
        let phaseName = phase.rawValue
        guard let currentStageIndex = stages.firstIndex(of: phaseName) else {
            if phase == .completed || phase == .completedWithWarnings {
                for stage in stages {
                    stageProgress[stage] = 1.0
                }
            }
            return
        }

        for (idx, stage) in stages.enumerated() {
            if idx < currentStageIndex {
                stageProgress[stage] = 1.0
            } else if idx == currentStageIndex {
                let current = stageProgress[stage] ?? 0.0
                stageProgress[stage] = max(current, max(0, min(1, fraction)))
            }
        }
    }

    private func renderLocked(finalStatePrefix: String? = nil) {
        guard isInteractiveTTY else { return }

        print("\u{001B}[H\u{001B}[2J", terminator: "")

        let prefix = finalStatePrefix ?? "RUN"
        let spinner = spinnerGlyphs[spinnerFrame]
        print("ForgeMedia CLI — Full Screen")
        print("============================")
        print("")
        print("[\(prefix)] \(spinner) File \(fileIndex)/\(fileTotal): \(title)")
        for stage in stages {
            let value = stageProgress[stage] ?? 0.0
            print("  \(stage.padding(toLength: 10, withPad: " ", startingAt: 0)) \(bar(value)) \(Int((value * 100).rounded()))%")
        }
        print("")
        print("  status     \(statusLabel)")
        print("")
        print("Ctrl+C to stop")
        fflush(stdout)
    }

    private func enterFullScreen() {
        guard !inFullScreen else { return }
        inFullScreen = true
        print("\u{001B}[?1049h\u{001B}[?25l", terminator: "")
        fflush(stdout)
    }

    private func leaveFullScreen() {
        guard inFullScreen else { return }
        inFullScreen = false
        print("\u{001B}[?25h\u{001B}[?1049l", terminator: "")
        fflush(stdout)
    }

    private func bar(_ value: Double) -> String {
        let width = 28
        let clamped = max(0, min(1, value))
        let filled = Int((clamped * Double(width)).rounded())
        let full = String(repeating: "█", count: filled)
        let empty = String(repeating: "░", count: max(0, width - filled))
        return "[\(full)\(empty)]"
    }
}

private let spinnerGlyphs = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

enum CLIError: LocalizedError {
    case missingInput
    case invalidMode
    case helpRequested

    var errorDescription: String? {
        switch self {
        case .missingInput: return "Missing --input"
        case .invalidMode: return "Invalid --mode (use single|multi|folder)"
        case .helpRequested: return "Help requested"
        }
    }
}

private let usage = """
Usage:
  fm /path/video.mp4
  fm /path/folder --recursive --preset dub_translate_en
  fm --mode single --input /path/video.mp4 [--preset convert_h264]
  fm --mode multi --input /path/a.mp4,/path/b.mov [--preset dub_translate_en]
  fm --mode folder --input /path/folder [--recursive|--no-recursive] [--preset convert_h264]

Presets:
  transcribe, dub_translate_en, convert_h264, convert_hevc, stitch, merge_audio
"""
