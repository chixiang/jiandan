import Foundation
import SwiftData

/// 用户自定义的物品分类
///
/// 与 `Category`（内置 enum）平级；两者在 UI 层统一由 `AnyCategory` 表达。
/// SwiftData 自动建表，无需手动 migration plan。
@Model
final class UserCategory {
    @Attribute(.unique) var id: UUID
    /// 显示名称（trim 后存储，1...nameMaxLength）
    var name: String
    /// SF Symbol 名称（运行时若无效则 UI 层 fallback 到 `defaultIcon`）
    var iconName: String
    /// 排序权重：值越小越靠前；新建默认 0
    var sortOrder: Int
    var createdAt: Date

    /// 名称长度上限
    static let nameMaxLength = 10

    /// iconName 为空时的 fallback
    static let defaultIcon = "tag"

    init(
        name: String,
        iconName: String,
        sortOrder: Int = 0
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmed.isEmpty, "UserCategory name cannot be empty")
        precondition(
            trimmed.count <= Self.nameMaxLength,
            "UserCategory name too long (max \(Self.nameMaxLength))"
        )

        self.id = UUID()
        self.name = trimmed
        self.iconName = iconName.isEmpty ? Self.defaultIcon : iconName
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}

// MARK: - 改写引用

/// 把所有 `categoryID == fromCategoryID` 的记录改写为 `toCategoryID`。
/// 用于"删除自定义分类时把引用记录归入'其他'"。
enum UserCategoryReassignService {
    @MainActor
    static func reassign(
        fromCategoryID: String,
        toCategoryID: String,
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.categoryRaw == fromCategoryID }
        )
        guard let records = try? context.fetch(descriptor) else { return }
        for record in records {
            record.categoryRaw = toCategoryID
        }
    }
}