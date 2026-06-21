import Foundation
import ForgeMediaDomain

/// Detects the spoken language of a media file without sending data off-device by default.
///
/// Detection strategy (in priority order):
///   1. ffprobe stream language metadata tag — instant, zero cost
///   2. Filename/path heuristics (e.g. folder named "es/", filename contains "_spa_")
///   3. Whisper subprocess (if `whisper` or `whisper-cpp` binary found on PATH)
///   4. Gemini Flash audio transcription (only when remoteAIAllowed == true)
///   5. Return `.unknown` and ask user to confirm
public actor LanguageDetectionService {
    private let ffprobePath: String
    private let geminiAPIKey: String?
    private let remoteAIAllowed: Bool

    public init(
        ffprobePath: String = "/opt/homebrew/bin/ffprobe",
        geminiAPIKey: String? = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
        remoteAIAllowed: Bool = false
    ) {
        self.ffprobePath = ffprobePath
        self.geminiAPIKey = geminiAPIKey
        self.remoteAIAllowed = remoteAIAllowed
    }

    // MARK: - Public API

    /// Detect language for a single media file.
    public func detect(url: URL) async -> LanguageDetectionResult {
        // 1. ffprobe metadata
        if let result = detectFromMetadata(url: url) { return result }

        // 2. Filename / path heuristics
        if let result = detectFromPath(url: url) { return result }

        // 3. Local whisper binary
        if let result = await detectWithLocalWhisper(url: url) { return result }

        // 4. Gemini (remote-AI gate)
        if remoteAIAllowed, let key = geminiAPIKey, !key.isEmpty {
            if let result = await detectWithGemini(url: url, apiKey: key) { return result }
        }

        return .unknown
    }

    /// Batch-detect languages for multiple files concurrently (max 4 at once).
    public func detectBatch(urls: [URL]) async -> [URL: LanguageDetectionResult] {
        await withTaskGroup(of: (URL, LanguageDetectionResult).self) { group in
            let semaphore = AsyncSemaphore(limit: 4)
            for url in urls {
                group.addTask {
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }
                    let result = await self.detect(url: url)
                    return (url, result)
                }
            }
            var results: [URL: LanguageDetectionResult] = [:]
            for await (url, result) in group {
                results[url] = result
            }
            return results
        }
    }

    // MARK: - Strategy 1: ffprobe metadata

    private func detectFromMetadata(url: URL) -> LanguageDetectionResult? {
        let ffprobe = findFFprobe()
        guard FileManager.default.isExecutableFile(atPath: ffprobe) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobe)
        process.arguments = ["-v", "quiet", "-print_format", "json",
                             "-show_streams", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let streams = json["streams"] as? [[String: Any]] else { return nil }

        // Look for language tag on audio streams first, then any stream
        let audioStreams = streams.filter { ($0["codec_type"] as? String) == "audio" }
        let candidates = audioStreams.isEmpty ? streams : audioStreams

        for stream in candidates {
            let tags = stream["tags"] as? [String: String] ?? [:]
            let langTag = (tags["language"] ?? tags["LANGUAGE"] ?? "").lowercased()
            guard !langTag.isEmpty, langTag != "und", langTag != "undefined" else { continue }

            // Try ISO 639-1 direct match
            if let lang = LanguageOption.all.first(where: { $0.id == langTag }) {
                return LanguageDetectionResult(language: lang, confidence: 0.95, source: .metadata)
            }
            // Try ISO 639-2 (3-letter) lookup
            if let lang = LanguageOption.fromISO639_2(code: langTag) {
                return LanguageDetectionResult(language: lang, confidence: 0.95, source: .metadata)
            }
        }
        return nil
    }

    // MARK: - Strategy 2: filename / path heuristics

    private func detectFromPath(url: URL) -> LanguageDetectionResult? {
        let text = url.path.lowercased()
        // Check path components for ISO 639-1 folder names (e.g. "/es/", "/fr/", "/de/")
        let components = url.pathComponents.map { $0.lowercased() }
        for component in components {
            if component.count == 2, let lang = LanguageOption.all.first(where: { $0.id == component }) {
                return LanguageDetectionResult(language: lang, confidence: 0.6, source: .heuristic)
            }
        }
        // Filename patterns like "_spa_", "_eng_", "_spa.", "_french.", "spanish_", etc.
        let patterns: [(pattern: String, code: String)] = [
            ("_eng_", "en"), ("_english_", "en"), ("english", "en"),
            ("_spa_", "es"), ("_spanish_", "es"), ("spanish", "es"),
            ("_fre_", "fr"), ("_french_", "fr"), ("french", "fr"),
            ("_ger_", "de"), ("_german_", "de"), ("german", "de"),
            ("_ita_", "it"), ("_italian_", "it"), ("italian", "it"),
            ("_por_", "pt"), ("_portuguese_", "pt"), ("portuguese", "pt"),
            ("_rus_", "ru"), ("_russian_", "ru"), ("russian", "ru"),
            ("_jpn_", "ja"), ("_japanese_", "ja"), ("japanese", "ja"),
            ("_kor_", "ko"), ("_korean_", "ko"), ("korean", "ko"),
            ("_zho_", "zh"), ("_chinese_", "zh"), ("chinese", "zh"),
            ("_ara_", "ar"), ("_arabic_", "ar"), ("arabic", "ar"),
            ("_hin_", "hi"), ("_hindi_", "hi"), ("hindi", "hi"),
        ]
        for (pattern, code) in patterns {
            if text.contains(pattern), let lang = LanguageOption.all.first(where: { $0.id == code }) {
                return LanguageDetectionResult(language: lang, confidence: 0.65, source: .heuristic)
            }
        }
        return nil
    }

    // MARK: - Strategy 3: local Whisper binary

    private func detectWithLocalWhisper(url: URL) async -> LanguageDetectionResult? {
        // Find whisper binary (CLI or Python module)
        let whisperPaths = [
            "/opt/homebrew/bin/whisper",
            "/usr/local/bin/whisper",
            "/usr/bin/whisper",
        ]
        let whisperBin = whisperPaths.first { FileManager.default.isExecutableFile(atPath: $0) }

        // Also check for Python whisper module
        let pythonPaths = ["/usr/local/bin/python3", "/opt/homebrew/bin/python3", "/usr/bin/python3"]
        let python = pythonPaths.first { FileManager.default.isExecutableFile(atPath: $0) }

        guard whisperBin != nil || python != nil else { return nil }

        // Extract 30 seconds of audio to a temp file
        guard let audioURL = await extractAudioSample(url: url, durationSeconds: 30) else { return nil }
        defer { try? FileManager.default.removeItem(at: audioURL) }

        if let bin = whisperBin {
            return await runWhisperBinary(bin, audioURL: audioURL)
        }
        if let py = python {
            return await runWhisperPython(py, audioURL: audioURL)
        }
        return nil
    }

    private func runWhisperBinary(_ bin: String, audioURL: URL) async -> LanguageDetectionResult? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        // whisper CLI: --task detect-language --model tiny
        process.arguments = ["--task", "detect-language", "--model", "tiny",
                             "--output_format", "json", audioURL.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return parseWhisperLanguageOutput(data)
    }

    private func runWhisperPython(_ python: String, audioURL: URL) async -> LanguageDetectionResult? {
        let script = """
import whisper, sys, json
model = whisper.load_model("tiny")
audio = whisper.load_audio(sys.argv[1])
audio = whisper.pad_or_trim(audio)
mel = whisper.log_mel_spectrogram(audio).to(model.device)
_, probs = model.detect_language(mel)
top = max(probs, key=probs.get)
print(json.dumps({"language": top, "confidence": float(probs[top])}))
"""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = ["-c", script, audioURL.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return parseWhisperLanguageOutput(data)
    }

    private func parseWhisperLanguageOutput(_ data: Data) -> LanguageDetectionResult? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["language"] as? String else { return nil }
        let confidence = json["confidence"] as? Double ?? 0.8
        if let lang = LanguageOption.all.first(where: { $0.whisperCode == code || $0.id == code }) {
            return LanguageDetectionResult(language: lang, confidence: confidence, source: .whisper)
        }
        return nil
    }

    // MARK: - Strategy 4: Gemini Flash audio detection

    private func detectWithGemini(url: URL, apiKey: String) async -> LanguageDetectionResult? {
        guard let audioURL = await extractAudioSample(url: url, durationSeconds: 15) else { return nil }
        defer { try? FileManager.default.removeItem(at: audioURL) }

        guard let audioData = try? Data(contentsOf: audioURL) else { return nil }
        let base64Audio = audioData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": "Listen to this audio clip and respond with ONLY the ISO 639-1 language code (e.g. 'es', 'fr', 'de', 'ja') and confidence 0-1. Format: {\"language\": \"XX\", \"confidence\": 0.95}. If unclear respond {\"language\": \"und\", \"confidence\": 0.0}"],
                    ["inline_data": ["mime_type": "audio/wav", "data": base64Audio]]
                ]
            ]],
            "generationConfig": ["maxOutputTokens": 64, "temperature": 0.0]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)"
        guard let endpoint = URL(string: urlStr) else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = response["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else { return nil }

        // Parse the JSON response from Gemini
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else { return nil }
        let jsonStr = String(cleaned[jsonStart...jsonEnd])
        guard let parsed = try? JSONSerialization.jsonObject(with: Data(jsonStr.utf8)) as? [String: Any],
              let code = parsed["language"] as? String,
              code != "und" else { return nil }
        let confidence = parsed["confidence"] as? Double ?? 0.75
        if let lang = LanguageOption.all.first(where: { $0.id == code }) {
            return LanguageDetectionResult(language: lang, confidence: confidence, source: .gemini)
        }
        return nil
    }

    // MARK: - Audio extraction helper

    private func extractAudioSample(url: URL, durationSeconds: Int) async -> URL? {
        let ffmpeg = findFFmpeg()
        guard FileManager.default.isExecutableFile(atPath: ffmpeg) else { return nil }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fm_lang_\(UUID().uuidString).wav")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y", "-i", url.path,
            "-t", "\(durationSeconds)",
            "-vn",                          // drop video
            "-acodec", "pcm_s16le",         // PCM WAV for widest whisper compat
            "-ar", "16000",                 // 16kHz (whisper standard)
            "-ac", "1",                     // mono
            tempURL.path
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        return process.terminationStatus == 0 ? tempURL : nil
    }

    // MARK: - Path helpers

    private func findFFmpeg() -> String {
        let candidates = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "/usr/bin/ffmpeg"
    }

    private func findFFprobe() -> String {
        // Try same directory as found ffmpeg
        let ffmpeg = findFFmpeg()
        let ffprobe = ffmpeg.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        if FileManager.default.isExecutableFile(atPath: ffprobe) { return ffprobe }
        let candidates = ["/opt/homebrew/bin/ffprobe", "/usr/local/bin/ffprobe", "/usr/bin/ffprobe"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? ffprobePath
    }
}

// MARK: - AsyncSemaphore (simple concurrency limiter)

private actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) { count = limit }

    func wait() async {
        if count > 0 {
            count -= 1
        } else {
            await withCheckedContinuation { waiters.append($0) }
        }
    }

    func signal() {
        if let next = waiters.first {
            waiters.removeFirst()
            next.resume()
        } else {
            count += 1
        }
    }
}
