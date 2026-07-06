import SwiftUI

/// 去向选择器
struct MethodPickerSection: View {
    @Binding var selection: FarewellMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("去向")
                .appFont(.sectionTitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FarewellMethod.allCases) { method in
                        MethodChip(
                            method: method,
                            isSelected: method == selection,
                            onTap: { selection = method }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

private struct MethodChip: View {
    @Environment(\.appTheme) private var theme
    let method: FarewellMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: method.icon)
                Text(method.localizedName)
            }
            .appFont(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? theme.accent.opacity(0.2) : theme.divider.opacity(0.3))
            .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection: FarewellMethod = .donate
    return MethodPickerSection(selection: $selection)
        .padding()
        .environment(\.appTheme, AppTheme(mode: .light))
}