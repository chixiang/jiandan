import SwiftUI

/// 设置面板：主题切换 + 预留更多选项
///
/// 主题切换直接绑定 `ThemeManager`（已用 `@Observable`），变更会立即生效
/// 并通过 `UserDefaults` 持久化（ThemeManager.init 自动恢复）。
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(CurrencyManager.self) private var currencyManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingCategoryManagement = false
    @State private var showingRestartAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
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

                    // 语言
                    VStack(alignment: .leading, spacing: 12) {
                        Text("语言")
                            .font(AppTypography.caption)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(AppLanguage.allCases) { lang in
                                LanguageOptionRow(
                                    lang: lang,
                                    isSelected: languageManager.language == lang,
                                    onSelect: {
                                        guard languageManager.language != lang else { return }
                                        languageManager.apply(lang)
                                        showingRestartAlert = true
                                    }
                                )

                                if lang != AppLanguage.allCases.last {
                                    Divider()
                                        .background(theme.divider)
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                    }

                    // 币种
                    VStack(alignment: .leading, spacing: 12) {
                        Text("币种")
                            .font(AppTypography.caption)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(Currency.allCases) { currency in
                                CurrencyOptionRow(
                                    currency: currency,
                                    isSelected: currencyManager.currency == currency,
                                    onSelect: {
                                        currencyManager.currency = currency
                                    }
                                )

                                if currency != Currency.allCases.last {
                                    Divider()
                                        .background(theme.divider)
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                    }

                    // 分类管理
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类")
                            .font(AppTypography.caption)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, 4)

                        Button(action: { showingCategoryManagement = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.accent)
                                Text("管理自定义分类")
                                    .font(AppTypography.body)
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(theme.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.background)
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
            .alert("切换语言", isPresented: $showingRestartAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("语言将在下次启动时切换。")
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
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
    .environment(CurrencyManager())
    .environment(LanguageManager())
}

/// 单个语言选项行
private struct LanguageOptionRow: View {
    @Environment(\.appTheme) private var theme
    let lang: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: lang.icon)
                    .font(.body)
                    .foregroundStyle(theme.primaryText)
                    .frame(width: 24)

                Text(lang.displayName)
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
        .accessibilityLabel("\(lang.displayName)\(isSelected ? "，已选中" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// 单个币种选项行
private struct CurrencyOptionRow: View {
    @Environment(\.appTheme) private var theme
    let currency: Currency
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: currency.icon)
                    .font(.body)
                    .foregroundStyle(theme.primaryText)
                    .frame(width: 24)

                Text(currency.displayName)
                    .font(AppTypography.body)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Text(currency.symbol)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondary)

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
        .accessibilityLabel("\(currency.displayName)\(isSelected ? "，已选中" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}