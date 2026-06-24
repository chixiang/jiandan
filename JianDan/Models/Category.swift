import Foundation
import SwiftData

/// 物品分类（内置 enum）
///
/// rawValue 是中文展示名。
/// 12 个内置 case 按"衣物 → 鞋包配饰 → 书籍 → 电子 → 家具 → 家居收纳 → 美妆护肤 → 票据文件 → 玩具收藏 → 工具器材 → 杂物 → 其他"排序。
/// 用户自定义分类见 `UserCategory`；两者通过 `AnyCategory` 统一表达。
enum Category: String, CaseIterable, Identifiable, Codable {
    case clothing = "衣物"
    case shoesAccessories = "鞋包配饰"
    case books = "书籍"
    case electronics = "电子"
    case furniture = "家具"
    case homeStorage = "家居收纳"
    case beauty = "美妆护肤"
    case documents = "票据文件"
    case toysCollectibles = "玩具收藏"
    case tools = "工具器材"
    case miscellaneous = "杂物"
    case other = "其他"

    var id: String { rawValue }

    /// SF Symbol 图标
    var icon: String {
        switch self {
        case .clothing: return "tshirt"
        case .shoesAccessories: return "bag"
        case .books: return "book"
        case .electronics: return "laptopcomputer"
        case .furniture: return "sofa"
        case .homeStorage: return "shippingbox.and.arrow.backward"
        case .beauty: return "sparkles"
        case .documents: return "doc.text"
        case .toysCollectibles: return "gamecontroller"
        case .tools: return "wrench.and.screwdriver"
        case .miscellaneous: return "shippingbox"
        case .other: return "circle.grid.2x2"
        }
    }
}

// MARK: - 统一表达

/// 分类的统一表达：内置枚举 OR 用户自定义
///
/// 在 UI / 统计 / 持久化读写处使用此枚举，避免散落的 `if category is ...` 判断。
enum AnyCategory: Hashable {
    case builtin(Category)
    case custom(UserCategory)

    var displayName: String {
        switch self {
        case .builtin(let c): return c.rawValue
        case .custom(let u): return u.name
        }
    }

    var iconName: String {
        switch self {
        case .builtin(let c): return c.icon
        case .custom(let u): return u.iconName
        }
    }

    /// 是否可删除（仅自定义可删）
    var isDeletable: Bool {
        if case .custom = self { return true }
        return false
    }

    /// 持久化字符串 ID：内置用 rawValue，自定义用 UUID
    var storageID: String {
        switch self {
        case .builtin(let c): return c.rawValue
        case .custom(let u): return u.id.uuidString
        }
    }

    /// 从持久化 ID 解析；若 context 传 nil，则只尝试 builtin（custom 总是 fallback 到 other）
    static func resolve(storageID: String, context: ModelContext? = nil) -> AnyCategory {
        if let builtin = Category(rawValue: storageID) {
            return .builtin(builtin)
        }
        // 自定义 UUID 形式：尝试从 context 查
        if let context, let uuid = UUID(uuidString: storageID) {
            let descriptor = FetchDescriptor<UserCategory>(
                predicate: #Predicate { $0.id == uuid }
            )
            if let match = try? context.fetch(descriptor).first {
                return .custom(match)
            }
        }
        return .builtin(.other)
    }
}