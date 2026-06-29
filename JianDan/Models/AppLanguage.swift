import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = ""
    case zhHans = "zh-Hans"
    case en = "en"
    case ja = "ja"

    var id: String { rawValue.isEmpty ? "system" : rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "跟随系统")
        case .zhHans: return "简体中文"
        case .en:     return "English"
        case .ja:     return "日本語"
        }
    }

    /// 跟随系统时解析当前系统语言，否则返回自身
    var resolvedForCurrentSystem: AppLanguage {
        guard self == .system else { return self }
        switch Locale.current.language.languageCode?.identifier {
        case "zh": return .zhHans
        case "en": return .en
        case "ja": return .ja
        default: return .en
        }
    }

    var icon: String {
        switch self {
        case .system: return "globe"
        case .zhHans: return "textformat.size"
        case .en:     return "a.circle"
        case .ja:     return "textformat.alt"
        }
    }
}
