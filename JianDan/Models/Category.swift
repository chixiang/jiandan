import Foundation

/// 物品分类
enum Category: String, CaseIterable, Identifiable, Codable {
    case clothing = "衣物"
    case books = "书籍"
    case electronics = "电子"
    case furniture = "家具"
    case miscellaneous = "杂物"
    case other = "其他"

    var id: String { rawValue }

    /// SF Symbol 图标
    var icon: String {
        switch self {
        case .clothing: return "tshirt"
        case .books: return "book"
        case .electronics: return "laptopcomputer"
        case .furniture: return "sofa"
        case .miscellaneous: return "shippingbox"
        case .other: return "circle.grid.2x2"
        }
    }
}
