import Foundation

/// 新建减单表单的纯函数校验器
///
/// 抽取自 `AddFarewellView` 的 `canSave` 计算属性，便于单元测试覆盖边界场景。
/// 视图侧只需：
/// ```swift
/// private var canSave: Bool { AddFarewellValidator.canSave(name: name) }
/// ```
enum AddFarewellValidator {

    /// 名称是否合法（trim 后非空且不超过上限）
    /// - Parameter name: 当前 TextField 的原始字符串
    /// - Returns: true = 可以保存
    static func canSave(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= FarewellRecord.nameMaxLength
    }
}