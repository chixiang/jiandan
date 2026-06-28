import Foundation
import SwiftData

/// 删除一条告别清单记录的服务
///
/// 抽取自 `FarewellDetailView.deleteRecord()` 的"清理照片 + 删记录 + 保存"流程，
/// 便于单元测试验证图片清理行为。
@MainActor
enum RecordDeleter {

    /// 删除一条记录及其关联的所有图片
    /// - Parameters:
    ///   - record: 待删除的记录
    ///   - context: 该记录所属的 SwiftData 上下文
    /// - Throws: SwiftData 保存失败时抛错；图片删除失败被吞掉（图片清理失败不应阻塞记录删除）
    static func delete(_ record: FarewellRecord, in context: ModelContext) throws {
        try? ImageStore.delete(filenames: record.photoFilenames)
        context.delete(record)
        try context.save()
    }
}