import SwiftUI
import ForgeMediaDomain

/// Searchable inline language picker used in the detection sheet and settings.
public struct LanguagePickerView: View {
    @Binding public var selection: LanguageOption
    public var includeAuto: Bool

    @State private var query: String = ""
    @State private var isExpanded: Bool = false

    public init(selection: Binding<LanguageOption>, includeAuto: Bool = false) {
        self._selection = selection
        self.includeAuto = includeAuto
    }

    private var catalog: [LanguageOption] {
        var list = LanguageOption.all
        if includeAuto { list.insert(.auto, at: 0) }
        if query.isEmpty { return list }
        let q = query.lowercased()
        return list.filter {
            $0.name.lowercased().contains(q) ||
            $0.nativeName.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    public var body: some View {
        Menu {
            TextField("Search languages…", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
                .padding(.top, 6)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(catalog) { lang in
                        Button {
                            selection = lang
                        } label: {
                            HStack(spacing: 8) {
                                if selection.id == lang.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(ForgeMediaTokens.Colors.accent)
                                        .frame(width: 14)
                                } else {
                                    Spacer().frame(width: 14)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(lang.name)
                                        .font(.system(.body, design: .default))
                                        .foregroundColor(ForgeMediaTokens.Colors.fg)
                                    if lang.id != "auto" && lang.id != "und" {
                                        Text(lang.nativeName)
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(ForgeMediaTokens.Colors.muted)
                                    }
                                }
                                Spacer()
                                Text(lang.id)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(ForgeMediaTokens.Colors.muted)
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: min(CGFloat(catalog.count) * 36, 280))
        } label: {
            HStack(spacing: 6) {
                Text(selection.name)
                    .font(.system(.callout, design: .default).weight(.medium))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)
                if selection.id != "auto" && selection.id != "und" {
                    Text("· \(selection.id)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(ForgeMediaTokens.Glass.surface)
            .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous)
                    .stroke(ForgeMediaTokens.Colors.border, lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
    }
}
