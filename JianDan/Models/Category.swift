import Foundation

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

    var localizedName: String {
        switch self {
        case .clothing: return String(localized: "衣物")
        case .shoesAccessories: return String(localized: "鞋包配饰")
        case .books: return String(localized: "书籍")
        case .electronics: return String(localized: "电子")
        case .furniture: return String(localized: "家具")
        case .homeStorage: return String(localized: "家居收纳")
        case .beauty: return String(localized: "美妆护肤")
        case .documents: return String(localized: "票据文件")
        case .toysCollectibles: return String(localized: "玩具收藏")
        case .tools: return String(localized: "工具器材")
        case .miscellaneous: return String(localized: "杂物")
        case .other: return String(localized: "其他")
        }
    }

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

/// 自定义分类存储 ID 前缀
private let customPrefix = "__custom__|"

// MARK: - 统一表达

/// 分类的统一表达：内置枚举 OR 用户自定义
///
/// 自定义分类存盘时把名称和图标名嵌入 storageID（`__custom__|name|iconName`），
/// 读盘时无需查询 UserCategory 表即可还原。这保证了：
/// 1. `FarewellRecord` 的 category 计算属性不需要 ModelContext
/// 2. 记录保留"告别时的分类名"——用户后来重命名不会追溯旧记录
enum AnyCategory: Hashable {
    case builtin(Category)
    /// name 和 iconName 编码在 storageID 中，查询时无需 ModelContext
    case custom(name: String, iconName: String)

    var displayName: String {
        switch self {
        case .builtin(let c): return c.localizedName
        case .custom(let name, _): return name
        }
    }

    var iconName: String {
        switch self {
        case .builtin(let c): return c.icon
        case .custom(_, let icon): return icon
        }
    }

    /// 是否可删除（仅自定义可删）
    var isDeletable: Bool {
        if case .custom = self { return true }
        return false
    }

    /// 持久化字符串 ID：内置用 rawValue，自定义用 `__custom__|name|iconName`
    var storageID: String {
        switch self {
        case .builtin(let c): return c.rawValue
        case .custom(let name, let icon): return "\(customPrefix)\(name)|\(icon)"
        }
    }

    /// 从持久化 ID 解析，不需要 ModelContext
    static func resolve(storageID: String) -> AnyCategory {
        if let builtin = Category(rawValue: storageID) {
            return .builtin(builtin)
        }
        if storageID.hasPrefix(customPrefix) {
            let body = storageID.dropFirst(customPrefix.count)
            let parts = body.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                return .custom(name: String(parts[0]), iconName: String(parts[1]))
            }
        }
        return .builtin(.other)
    }

    /// 从 `UserCategory` 实例构造 AnyCategory（仅 UI 层用于 picker selection，不用于存盘）
    static func from(userCategory: UserCategory) -> AnyCategory {
        .custom(name: userCategory.name, iconName: userCategory.iconName)
    }

    /// 构造一个用于`#Predicate`匹配的 storageID（删除自定义分类时找出所有引用记录）
    static func storageIDForDelete(userCategory: UserCategory) -> String {
        "\(customPrefix)\(userCategory.name)|\(userCategory.iconName)"
    }
}