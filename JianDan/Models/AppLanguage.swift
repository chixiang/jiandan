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

    var icon: String {
        switch self {
        case .system: return "globe"
        case .zhHans: return "textformat.size"
        case .en:     return "a.circle"
        case .ja:     return "textformat.alt"
        }
    }
}
