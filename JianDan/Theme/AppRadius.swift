import CoreGraphics

/// 告别清单圆角规范：3 档
///
/// - `chip`:  8 —— 缩略图、小方块、紧凑按钮
/// - `card`: 12 —— 中等卡片（照片轮播、告别留言、引言）
/// - `sheet`: 16 —— 大卡片（列表卡片、设置组、统计卡）
///
/// 用法：
/// ```swift
/// .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
/// ```
enum AppRadius {
    static let chip: CGFloat = 8
    static let card: CGFloat = 12
    static let sheet: CGFloat = 16
}