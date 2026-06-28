import Foundation
import SwiftData

/// 编辑告别表单的保存辅助函数
///
/// 抽取自 `EditFarewellView` 的若干 `.onChange` 截断逻辑 + `save()` 方法。
/// 视图侧调用示例：
/// ```swift
/// .onChange(of: record.name) { _, _ in
///     EditFarewellSaver.truncateName(record)
/// }
/// ```
@MainActor
enum EditFarewellSaver {

    /// 截断 name 字段至 `FarewellRecord.nameMaxLength`
    static func truncateName(_ record: FarewellRecord) {
        if record.name.count > FarewellRecord.nameMaxLength {
            record.name = String(record.name.prefix(FarewellRecord.nameMaxLength))
        }
    }

    /// 截断 farewellLetter 字段至 `FarewellRecord.farewellLetterMaxLength`
    static func truncateFarewellLetter(_ record: FarewellRecord) {
        if let letter = record.farewellLetter,
           letter.count > FarewellRecord.farewellLetterMaxLength {
            record.farewellLetter = String(letter.prefix(FarewellRecord.farewellLetterMaxLength))
        }
    }

    /// 截断 recipientDetail 字段至 `FarewellRecord.recipientDetailMaxLength`
    static func truncateRecipientDetail(_ record: FarewellRecord) {
        if let detail = record.recipientDetail,
           detail.count > FarewellRecord.recipientDetailMaxLength {
            record.recipientDetail = String(detail.prefix(FarewellRecord.recipientDetailMaxLength))
        }
    }

    /// 保存编辑结果：刷新 updatedAt 后写入 context
    /// - Throws: SwiftData 保存失败时抛错
    static func save(_ record: FarewellRecord, in context: ModelContext) throws {
        record.updatedAt = .now
        try context.save()
    }
}