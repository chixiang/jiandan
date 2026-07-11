import Foundation

/// 告别方式
enum FarewellMethod: String, CaseIterable, Identifiable, Codable {
    case discard = "扔掉"
    case gift = "送人"
    case donate = "捐赠"
    case resell = "二手出售"
    case store = "暂存"
    case other = "其他"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .gift: return String(localized: "送人")
        case .discard: return String(localized: "扔掉")
        case .donate: return String(localized: "捐赠")
        case .resell: return String(localized: "二手出售")
        case .store: return String(localized: "暂存")
        case .other: return String(localized: "其他")
        }
    }

    /// SF Symbol 图标
    var icon: String {
        switch self {
        case .gift: return "gift"
        case .discard: return "trash"
        case .donate: return "heart"
        case .resell: return "tag"
        case .store: return "archivebox"
        case .other: return "ellipsis.circle"
        }
    }
}
