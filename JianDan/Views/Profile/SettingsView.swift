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
                VStack(alignment: .leading, spacing: .md) {
                    // 分组标题
                    Text("外观")
                        .font(AppTypography.caption.font)
                        .foregroundStyle(theme.secondary)
                        .tracking(2)
                        .padding(.horizontal, .xs)

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
                                    .padding(.leading, .md)
                            }
                        }
                    }
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                            .strokeBorder(theme.divider, lineWidth: 0.5)
                    )
                    .animation(.easeInOut(duration: 0.6), value: theme.cardBackground)

                    // 语言
                    VStack(alignment: .leading, spacing: .sm) {
                        Text("语言")
                            .font(AppTypography.caption.font)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, .xs)

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
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                        .animation(.easeInOut(duration: 0.6), value: theme.cardBackground)
                    }

                    // 币种
                    VStack(alignment: .leading, spacing: .sm) {
                        Text("币种")
                            .font(AppTypography.caption.font)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, .xs)

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
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                        .animation(.easeInOut(duration: 0.6), value: theme.cardBackground)
                    }

                    // 分类管理
                    VStack(alignment: .leading, spacing: .sm) {
                        Text("分类")
                            .font(AppTypography.caption.font)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, .xs)

                        Button(action: { showingCategoryManagement = true }) {
                            HStack(spacing: .sm) {
                                Image(systemName: "tag")
                                    .appFont(.body)
                                    .foregroundStyle(theme.accent)
                                Text("管理自定义分类")
                                    .appFont(.body)
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .appFont(.caption)
                                    .foregroundStyle(theme.secondary)
                            }
                            .padding(.horizontal, .md)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                        .animation(.easeInOut(duration: 0.6), value: theme.cardBackground)
                    }

                    // 关于
                    VStack(alignment: .leading, spacing: .sm) {
                        Text("关于")
                            .font(AppTypography.caption.font)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                            .padding(.horizontal, .xs)

                        VStack(spacing: 0) {
                            HStack(spacing: .sm) {
                                Image(systemName: "info.circle")
                                    .appFont(.body)
                                    .foregroundStyle(theme.accent)
                                    .frame(width: 24)
                                Text("应用")
                                    .appFont(.body)
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Text("app_display_name")
                                    .appFont(.body)
                                    .foregroundStyle(theme.secondary)
                            }
                            .padding(.horizontal, .md)
                            .padding(.vertical, 14)

                            Divider()
                                .background(theme.divider)
                                .padding(.leading, 52)

                            HStack(spacing: .sm) {
                                Image(systemName: "tag")
                                    .appFont(.body)
                                    .foregroundStyle(theme.accent)
                                    .frame(width: 24)
                                Text("版本")
                                    .appFont(.body)
                                    .foregroundStyle(theme.primaryText)
                                Spacer()
                                Text(versionString)
                                    .appFont(.body)
                                    .foregroundStyle(theme.secondary)
                            }
                            .padding(.horizontal, .md)
                            .padding(.vertical, 14)
                        }
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                                .strokeBorder(theme.divider, lineWidth: 0.5)
                        )
                        .animation(.easeInOut(duration: 0.6), value: theme.cardBackground)
                    }
                }
                .padding(.horizontal, .screenPadding)
                .padding(.vertical, .sm)
            }
            .background(theme.background)
            .animation(.easeInOut(duration: 0.6), value: theme.background)
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

private extension SettingsView {
    var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
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
            HStack(spacing: .sm) {
                // 色块预览
                Circle()
                    .fill(swatchColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().strokeBorder(theme.divider, lineWidth: 0.5)
                    )

                Text(mode.displayName)
                    .appFont(.body)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .appFont(.body)
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, .md)
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
            HStack(spacing: .sm) {
                Image(systemName: lang.icon)
                    .appFont(.body)
                    .foregroundStyle(theme.primaryText)
                    .frame(width: 24)

                Text(lang.displayName)
                    .appFont(.body)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .appFont(.body)
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, .md)
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
            HStack(spacing: .sm) {
                Image(systemName: currency.icon)
                    .appFont(.body)
                    .foregroundStyle(theme.primaryText)
                    .frame(width: 24)

                Text(currency.displayName)
                    .appFont(.body)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Text(currency.symbol)
                    .appFont(.body)
                    .foregroundStyle(theme.secondary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .appFont(.body)
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, .md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currency.displayName)\(isSelected ? "，已选中" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}