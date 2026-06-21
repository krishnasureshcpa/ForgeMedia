import SwiftUI
import ForgeMediaDomain

// MARK: - Preset Metadata

/// Rich human-readable metadata for each built-in preset.
/// Shown in the picker panel — name, tagline, plain-English description.
public struct PresetMeta: Identifiable, Sendable {
    public let id: String              // matches MediaPreset.id
    public let icon: String            // SF Symbol
    public let name: String            // "Convert to H.264"
    public let tagline: String         // one-liner for non-technical users
    public let technical: String       // codec/format string shown in small text
    public let description: String     // paragraph shown in the detail panel
    public let typicalTime: String     // "~5 min per hour of footage"
    public let privacyNote: String?    // shown only when AI/network is involved
    public let category: Category

    public enum Category: String, Sendable {
        case convert  = "Convert"
        case audio    = "Audio"
        case ai       = "Transcribe & Translate"
        case restore  = "Restore & Upscale"
    }

    public static let all: [PresetMeta] = [

        // ── Convert ─────────────────────────────────────────────────────────
        .init(
            id: "convert_h264",
            icon: "film",
            name: "Convert to H.264",
            tagline: "Make it play everywhere",
            technical: "H.264 · AAC · MP4",
            description: "Converts your video into the most widely understood format on the planet. Every phone, TV, browser, social platform, and editing app knows how to play H.264. If you're ever unsure which preset to choose, start here.",
            typicalTime: "~5 min per hour of footage",
            privacyNote: nil,
            category: .convert
        ),
        .init(
            id: "convert_hevc",
            icon: "archivebox",
            name: "Smaller File, Same Quality",
            tagline: "Half the storage, same sharpness",
            technical: "H.265 (HEVC) · AAC · MP4",
            description: "Fits twice as much footage into the same amount of storage — without any visible drop in quality. Great for archiving or sending large files. One caveat: devices made before 2017 may not support this format.",
            typicalTime: "~6 min per hour of footage",
            privacyNote: nil,
            category: .convert
        ),
        .init(
            id: "stitch",
            icon: "link",
            name: "Join Clips Together",
            tagline: "Glue multiple videos into one file",
            technical: "AVFoundation · MP4 · passthrough",
            description: "Merges as many video files as you want, end-to-end, into a single video. No re-encoding means the quality stays exactly as-is and it finishes almost instantly. Perfect for multi-part recordings or series episodes.",
            typicalTime: "~30 seconds per hour of footage",
            privacyNote: nil,
            category: .convert
        ),

        // ── Audio ────────────────────────────────────────────────────────────
        .init(
            id: "merge_audio",
            icon: "waveform.path.badge.plus",
            name: "Swap the Audio Track",
            tagline: "Replace what viewers hear",
            technical: "AVFoundation · MP4 · AAC",
            description: "Swaps the video's original audio for a different audio file you provide. Useful for replacing a noisy on-set recording with a clean studio take, or adding a music track over silent footage.",
            typicalTime: "~1 min per hour of footage",
            privacyNote: nil,
            category: .audio
        ),

        // ── Transcribe & AI ──────────────────────────────────────────────────
        .init(
            id: "transcribe",
            icon: "text.bubble",
            name: "Transcribe Speech to Text",
            tagline: "Turn every spoken word into readable text",
            technical: "Whisper AI · SRT subtitle file",
            description: "Listens to your video and writes down everything that's said, with accurate timestamps for each sentence. Delivers a subtitle file (.srt) that you can read, search, and edit in any text editor. Everything runs on your Mac — no audio ever leaves your device.",
            typicalTime: "~10 min per hour (Apple Silicon)",
            privacyNote: "Runs 100% on your Mac. No audio sent anywhere.",
            category: .ai
        ),
        .init(
            id: "transcribe_translate",
            icon: "globe",
            name: "Transcribe + Translate to English",
            tagline: "Understand videos in any language",
            technical: "Whisper AI · SRT · translated to EN",
            description: "Transcribes speech in any language and simultaneously translates it into English text. Produces an English subtitle file so you can follow along with content originally recorded in Spanish, French, Mandarin, Japanese, or dozens of other languages.",
            typicalTime: "~12 min per hour (Apple Silicon)",
            privacyNote: "Runs 100% on your Mac. No audio sent anywhere.",
            category: .ai
        ),
        .init(
            id: "dub_translate_en",
            icon: "mic.fill",
            name: "Dub into English",
            tagline: "Give your video a natural English voice",
            technical: "open-dubbing · H.264 · AAC",
            description: "Replaces the original spoken audio with an AI-generated English voice that matches the timing of the original speech — similar to how foreign-language films are professionally dubbed for English audiences.",
            typicalTime: "~20–40 min per hour of footage",
            privacyNote: "Runs locally via open-dubbing. Enable in Settings → Privacy to use.",
            category: .ai
        ),

        // ── Restore & Upscale ────────────────────────────────────────────────
        .init(
            id: "restore_clean",
            icon: "sparkles",
            name: "Stabilize + Denoise",
            tagline: "Fix shaky, grainy footage",
            technical: "FFmpeg · HEVC · stabilize + hqdn3d",
            description: "Smooths out camera shake and removes the grain and noise common in handheld, drone, or low-light footage. The output looks steadier and cleaner — like it was shot on a tripod in good lighting.",
            typicalTime: "~15 min per hour of footage",
            privacyNote: nil,
            category: .restore
        ),
        .init(
            id: "restore_4k",
            icon: "4k.tv",
            name: "Clean + Upscale to 4K",
            tagline: "Make older footage look modern",
            technical: "MetalFX upscale · HEVC · AAC",
            description: "First cleans up shake and grain, then uses Apple's MetalFX engine to upscale the resolution to 4K. Older footage looks noticeably sharper on modern TVs and displays. Runs entirely on your GPU — no cloud required.",
            typicalTime: "~30 min per hour (Apple Silicon)",
            privacyNote: nil,
            category: .restore
        ),
        .init(
            id: "restore_4k_ml",
            icon: "cpu",
            name: "AI Upscale to 4K (Real-ESRGAN)",
            tagline: "Maximum quality — worth the wait",
            technical: "Real-ESRGAN per-frame · HEVC · AAC",
            description: "The most powerful restoration available. A machine-learning model examines every single frame and reconstructs fine details, textures, and edges before upscaling to 4K. The difference is dramatic — but plan a few hours for long footage.",
            typicalTime: "~3–4 hrs per hour (Apple Silicon)",
            privacyNote: nil,
            category: .restore
        ),
    ]

    public static func find(id: String) -> PresetMeta? {
        all.first { $0.id == id }
    }
}

// MARK: - Preset Picker View

/// Two-panel preset picker shown as a popover.
/// Left: grouped option list. Right: plain-English description of the hovered item.
/// Solves the dropdown-clipping issue by using SwiftUI `.popover`.
public struct PresetPickerView: View {
    @Binding public var selectedPresetID: String
    @Environment(\.dismiss) private var dismiss

    @State private var hoveredID: String? = nil

    public init(selectedPresetID: Binding<String>) {
        self._selectedPresetID = selectedPresetID
    }

    private var categories: [PresetMeta.Category] {
        var seen = Set<PresetMeta.Category>()
        var order: [PresetMeta.Category] = []
        for m in PresetMeta.all {
            if seen.insert(m.category).inserted { order.append(m.category) }
        }
        return order
    }

    private var focusedMeta: PresetMeta? {
        if let h = hoveredID, let m = PresetMeta.find(id: h) { return m }
        return PresetMeta.find(id: selectedPresetID)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            optionList
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            detailPanel
        }
        .frame(width: 580, height: 360)
        .background(ForgeMediaTokens.Colors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Left: Option List

    private var optionList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(categories, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
        }
        .frame(width: 256)
        .background(ForgeMediaTokens.Colors.canvas)
    }

    private func categorySection(_ category: PresetMeta.Category) -> some View {
        let items = PresetMeta.all.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text(category.rawValue.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(items) { meta in
                PresetOptionRow(
                    meta: meta,
                    isSelected: selectedPresetID == meta.id,
                    isHovered: hoveredID == meta.id,
                    onHover: { hoveredID = $0 ? meta.id : nil },
                    onSelect: {
                        selectedPresetID = meta.id
                        dismiss()
                    }
                )
            }

            Divider()
                .overlay(ForgeMediaTokens.Colors.borderSubtle.opacity(0.5))
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Right: Detail Panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let meta = focusedMeta {
                detailContent(meta)
            } else {
                defaultHint
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ForgeMediaTokens.Colors.secondarySurface)
        .animation(ForgeMediaTokens.Motion.snappy, value: focusedMeta?.id)
    }

    private func detailContent(_ meta: PresetMeta) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header strip
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ForgeMediaTokens.Colors.brandSofter)
                        .frame(width: 34, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
                        )
                    Image(systemName: meta.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ForgeMediaTokens.Colors.brand)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meta.name)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                    Text(meta.tagline)
                        .font(.system(size: 11))
                        .foregroundColor(ForgeMediaTokens.Colors.brand)
                }
            }
            .padding(14)
            .background(ForgeMediaTokens.Colors.menuBar)
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)

            // Description
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(meta.description)
                        .font(.system(size: 12))
                        .foregroundColor(ForgeMediaTokens.Colors.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider().overlay(ForgeMediaTokens.Colors.borderSubtle)

                    // Stats row
                    VStack(alignment: .leading, spacing: 6) {
                        infoRow(icon: "timer", label: "Typical time", value: meta.typicalTime)
                        infoRow(icon: "doc.badge.gearshape", label: "Format", value: meta.technical)
                        if let note = meta.privacyNote {
                            infoRow(icon: "lock.fill", label: "Privacy", value: note)
                        }
                    }
                }
                .padding(14)
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                .frame(width: 12)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                Text(value)
                    .font(.system(size: 11))
                    .foregroundColor(ForgeMediaTokens.Colors.body)
            }
        }
    }

    private var defaultHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.point.up.left")
                .font(.system(size: 22))
                .foregroundColor(ForgeMediaTokens.Colors.borderSubtle)
            Text("Hover over a preset to see\nwhat it does in plain English")
                .font(.system(size: 11))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Option Row

private struct PresetOptionRow: View {
    let meta: PresetMeta
    let isSelected: Bool
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Checkmark / icon area
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(ForgeMediaTokens.Colors.brand)
                    }
                }
                .frame(width: 14)

                // Icon
                Image(systemName: meta.icon)
                    .font(.system(size: 12))
                    .foregroundColor(
                        isSelected
                        ? ForgeMediaTokens.Colors.brand
                        : isHovered
                            ? ForgeMediaTokens.Colors.heading
                            : ForgeMediaTokens.Colors.bodySubtle
                    )
                    .frame(width: 16)

                // Name + tagline
                VStack(alignment: .leading, spacing: 1) {
                    Text(meta.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected
                            ? ForgeMediaTokens.Colors.heading
                            : ForgeMediaTokens.Colors.body
                        )
                    Text(meta.tagline)
                        .font(.system(size: 10))
                        .foregroundColor(
                            isHovered
                            ? ForgeMediaTokens.Colors.brand
                            : ForgeMediaTokens.Colors.bodySubtle
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected
                ? ForgeMediaTokens.Colors.brandSofter
                : isHovered
                    ? ForgeMediaTokens.Colors.menuBar
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { onHover($0) }
    }
}

// MARK: - Compact Picker Button

/// The button shown in the action strip — opens the PresetPickerView popover.
public struct PresetPickerButton: View {
    @Binding public var selectedPresetID: String
    let presets: [MediaPreset]

    @State private var showPicker = false

    public init(selectedPresetID: Binding<String>, presets: [MediaPreset]) {
        self._selectedPresetID = selectedPresetID
        self.presets = presets
    }

    private var displayName: String {
        PresetMeta.find(id: selectedPresetID)?.name
        ?? presets.first { $0.id == selectedPresetID }?.name
        ?? "Choose preset…"
    }

    private var tagline: String? {
        PresetMeta.find(id: selectedPresetID)?.tagline
    }

    public var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                        .lineLimit(1)
                    if let tag = tagline {
                        Text(tag)
                            .font(.system(size: 9))
                            .foregroundColor(ForgeMediaTokens.Colors.brand)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }
            .padding(.horizontal, 10)
            .frame(width: 200, height: tagline != nil ? 38 : 28)
            .background(
                showPicker
                ? ForgeMediaTokens.Colors.brandSofter
                : ForgeMediaTokens.Colors.canvas
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        showPicker
                        ? ForgeMediaTokens.Colors.borderBrand
                        : ForgeMediaTokens.Colors.borderDefault,
                        lineWidth: 1
                    )
            )
            .animation(ForgeMediaTokens.Motion.snappy, value: showPicker)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            PresetPickerView(selectedPresetID: $selectedPresetID)
        }
    }
}
