import SwiftUI

/// 设置面板：主题切换 + 预留更多选项
///
/// 主题切换直接绑定 `ThemeManager`（已用 `@Observable`），变更会立即生效
/// 并通过 `UserDefaults` 持久化（ThemeManager.init 自动恢复）。
struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分组标题
            Text("外观")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)
                .padding(.horizontal, 4)

            // 主题选项
            VStack(spacing: 0) {
                ForEach(AppThemeMode.allCases) { mode in
                    ThemeOptionRow(
                        mode: mode,
                        isSelected: themeManager.mode == mode,
                        onSelect: {
                            themeManager.mode = mode
                        }
                    )

                    if mode != AppThemeMode.allCases.last {
                        Divider()
                            .background(theme.divider)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(theme.divider, lineWidth: 0.5)
            )

            // 预留：更多设置（占位）
            Text("更多设置敬请期待")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 8)
        }
    }
}

/// 单个主题选项行
private struct ThemeOptionRow: View {
    @Environment(\.appTheme) private var theme
    let mode: AppThemeMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 色块预览
                Circle()
                    .fill(swatchColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().strokeBorder(theme.divider, lineWidth: 0.5)
                    )

                Text(mode.displayName)
                    .font(AppTypography.body)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.displayName)主题\(isSelected ? "，已选中" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 主题色块预览（用主题本身的 accent 色 + 中性背景）
    private var swatchColor: Color {
        switch mode {
        case .light:
            return AppColors.Light.accent
        case .dark:
            return AppColors.Dark.accent
        case .ink:
            return AppColors.Ink.accent
        }
    }
}

#Preview {
    let theme = AppTheme(mode: .light)
    return ScrollView {
        SettingsView()
            .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
    .environment(ThemeManager())
}