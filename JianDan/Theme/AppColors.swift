import SwiftUI

/// 告别清单品牌色板
///
/// 极简、雅致、留白 —— 三种色调供用户在 Settings 中切换：
/// - 浅色 (Light): 素白底 + 墨灰字 + 青碧点缀
/// - 深色 (Dark): 墨黑底 + 米白字 + 淡青点缀
/// - 墨色 (Ink):  纯黑底 + 米白字 + 朱砂点缀 (极致黑白红)
enum AppColors {
    // MARK: - 浅色

    enum Light {
        static let background = Color(red: 0.96, green: 0.95, blue: 0.94)      // #F4F3F0 素白
        static let primaryText = Color(red: 0.24, green: 0.24, blue: 0.24)     // #3C3C3C 墨灰
        static let accent = Color(red: 0.35, green: 0.58, blue: 0.55)          // #5A958D 青碧
        static let secondary = Color(red: 0.55, green: 0.53, blue: 0.51)       // #8C8782 烟灰
        static let cardBackground = Color.white
        static let divider = Color(red: 0.84, green: 0.82, blue: 0.80)        // #D6D1CC 浅灰
    }

    // MARK: - 深色

    enum Dark {
        static let background = Color(red: 0.10, green: 0.10, blue: 0.10)      // #1A1A1A 墨黑
        static let primaryText = Color(red: 0.96, green: 0.94, blue: 0.91)     // #F5F0E8 米白
        static let accent = Color(red: 0.48, green: 0.66, blue: 0.63)          // #7BA8A0 淡青
        static let secondary = Color(red: 0.54, green: 0.54, blue: 0.54)       // #8A8A8A 银灰
        static let cardBackground = Color(red: 0.16, green: 0.16, blue: 0.16)
        static let divider = Color(red: 0.25, green: 0.25, blue: 0.25)
    }

    // MARK: - 墨色（极致的黑白红）

    enum Ink {
        static let background = Color.black                                       // #000000
        static let primaryText = Color(red: 0.96, green: 0.94, blue: 0.91)     // #F5F0E8 米白
        static let accent = Color(red: 0.55, green: 0.23, blue: 0.23)          // #8B3A3A 深朱砂
        static let secondary = Color(red: 0.43, green: 0.43, blue: 0.43)       // #6E6E6E 烟灰
        static let cardBackground = Color(red: 0.07, green: 0.07, blue: 0.07)
        static let divider = Color(red: 0.20, green: 0.20, blue: 0.20)
    }
}

/// 告别清单主题模式
///
/// `rawValue` 同时是 UserDefaults 的存储键、显示名和 `init(rawValue:)` 恢复键。
enum AppThemeMode: String, CaseIterable, Identifiable, Codable {
    case light = "浅色"
    case dark = "深色"
    case ink = "墨色"

    var id: String { rawValue }

    /// 用户友好的描述（与 rawValue 相同，但显式提供方便调用）
    var displayName: String {
        switch self {
        case .light: return String(localized: "素笺")
        case .dark: return String(localized: "暮色")
        case .ink: return String(localized: "朱墨")
        }
    }

    /// 对应的系统 `ColorScheme`。
    /// Light 用 `.light`；Dark 和 Ink 均为深色 UI，但通过自定义色板覆盖背景。
    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark, .ink: return .dark
        }
    }
}
