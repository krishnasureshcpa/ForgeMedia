import Foundation
import ForgeMediaDomain

/// Shared output path resolution using user-configured file and folder suffixes.
///
/// Reads `fileSuffix` and `folderSuffix` from UserDefaults (defaulting to
/// `_ForgeMedia`). When `job.intakeRootFolderURL` is set, mirrors the source
/// subfolder hierarchy inside an output root folder that carries the folder
/// suffix. Each intermediate subfolder also receives the folder suffix.
enum OutputNaming {
    static func resolveOutputURL(for job: JobRecord, preset: MediaPreset) -> URL {
        if let explicit = job.outputURL { return explicit }

        let defaults = UserDefaults.standard
        let fileSuffix = defaults.string(forKey: "fileSuffix").flatMap { $0.isEmpty ? nil : $0 } ?? "_ForgeMedia"
        let folderSuffix = defaults.string(forKey: "folderSuffix").flatMap { $0.isEmpty ? nil : $0 } ?? "_ForgeMedia"
        let configuredOutputDir = defaults.string(forKey: "outputDirectory") ?? ""

        let ext = preset.outputContainer.isEmpty ? "mp4" : preset.outputContainer
        let stem = job.sourceURL.deletingPathExtension().lastPathComponent

        if let rootFolder = job.intakeRootFolderURL {
            // Determine parent dir for the output root folder
            let baseDir: URL = configuredOutputDir.isEmpty
                ? rootFolder.deletingLastPathComponent()
                : URL(fileURLWithPath: configuredOutputDir)

            let outputRootFolder = baseDir.appendingPathComponent(rootFolder.lastPathComponent + folderSuffix)

            // Mirror subfolder structure with folder suffix applied to each component
            var outputDir = outputRootFolder
            let sourcePath = job.sourceURL.path
            let rootPath = rootFolder.path
            if sourcePath.hasPrefix(rootPath + "/") {
                let relativePath = String(sourcePath.dropFirst(rootPath.count + 1))
                // Drop the filename; only keep intermediate subfolder components
                let subfolderComponents = relativePath.split(separator: "/").dropLast()
                for component in subfolderComponents {
                    outputDir = outputDir.appendingPathComponent(component + folderSuffix)
                }
            }

            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            return outputDir.appendingPathComponent(stem + fileSuffix).appendingPathExtension(ext)
        }

        // Single-file intake: place output alongside source (or in configured dir)
        let outputDir: URL = configuredOutputDir.isEmpty
            ? job.sourceURL.deletingLastPathComponent()
            : URL(fileURLWithPath: configuredOutputDir)
        return outputDir.appendingPathComponent(stem + fileSuffix).appendingPathExtension(ext)
    }
}
