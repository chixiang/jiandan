import SwiftUI

/// 减单字体规范：衬线 (Serif) 标题 + 系统默认正文
///
/// 中文环境下 `.serif` design 会自动选用系统提供的宋体类字形（PingFang SC 的衬线变体 / Songti SC），
/// 英文环境则给出经典 serif 气质，统一整个产品的"雅致"基调。
enum AppTypography {
    /// 大标题（如 Onboarding 主标题）
    static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.regular)

    /// 二级标题（如 Navigation Title）
    static let title = Font.system(.title2, design: .serif).weight(.regular)

    /// 三级标题（如卡片标题）
    static let headline = Font.system(.headline, design: .serif).weight(.regular)

    /// 正文
    static let body = Font.system(.body, design: .default)

    /// 副文 / 说明
    static let caption = Font.system(.caption, design: .default)

    /// 数字（如统计页大数字）
    static let stat = Font.system(size: 36, weight: .light, design: .serif)
}
