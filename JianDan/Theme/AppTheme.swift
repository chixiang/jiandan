import SwiftUI

/// 告别清单主题环境：贯穿整个 View 树
///
/// 用法：
/// ```swift
/// struct SomeView: View {
///     @Environment(\.appTheme) private var theme
///     var body: some View {
///         Text("hello").foregroundStyle(theme.primaryText)
///     }
/// }
/// ```
struct AppTheme {
    let mode: AppThemeMode

    var background: Color {
        switch mode {
        case .light: return AppColors.Light.background
        case .dark: return AppColors.Dark.background
        case .ink: return AppColors.Ink.background
        }
    }

    var primaryText: Color {
        switch mode {
        case .light: return AppColors.Light.primaryText
        case .dark: return AppColors.Dark.primaryText
        case .ink: return AppColors.Ink.primaryText
        }
    }

    var accent: Color {
        switch mode {
        case .light: return AppColors.Light.accent
        case .dark: return AppColors.Dark.accent
        case .ink: return AppColors.Ink.accent
        }
    }

    var secondary: Color {
        switch mode {
        case .light: return AppColors.Light.secondary
        case .dark: return AppColors.Dark.secondary
        case .ink: return AppColors.Ink.secondary
        }
    }

    var cardBackground: Color {
        switch mode {
        case .light: return AppColors.Light.cardBackground
        case .dark: return AppColors.Dark.cardBackground
        case .ink: return AppColors.Ink.cardBackground
        }
    }

    var divider: Color {
        switch mode {
        case .light: return AppColors.Light.divider
        case .dark: return AppColors.Dark.divider
        case .ink: return AppColors.Ink.divider
        }
    }

    /// 浅色主题需要阴影；深色/墨色用干净平面更好
    var needsShadow: Bool {
        mode == .light
    }
}

/// SwiftUI Environment Key
private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = AppTheme(mode: .light)
}

extension EnvironmentValues {
    /// 当前 `AppTheme`（颜色板 + 字体均可经此访问）
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

/// View Modifier：注入主题环境 + 切换系统色板 + 覆盖 tint 色
struct AppThemeModifier: ViewModifier {
    let mode: AppThemeMode

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, AppTheme(mode: mode))
            .preferredColorScheme(mode.colorScheme)
            .tint(AppTheme(mode: mode).accent)
    }
}

extension View {
    /// 应用告别清单主题。挂载在 Root 视图即可。
    func appTheme(_ mode: AppThemeMode) -> some View {
        modifier(AppThemeModifier(mode: mode))
    }
}
