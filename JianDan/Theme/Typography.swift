import SwiftUI

/// 告别清单字体规范：衬线 (Serif) 标题 + 系统默认正文
///
/// 中文环境下 `.serif` design 会自动选用系统提供的宋体类字形（PingFang SC 的衬线变体 / Songti SC），
/// 英文环境则给出经典 serif 气质，统一整个产品的"雅致"基调。
///
/// 每个 token 同时提供 `font` 和 `tracking`，通过 `.appFont(_:)` 修饰符一次性应用。
enum AppTypography {
    /// 大标题（如 Onboarding 主标题 / 物品名称）
    case largeTitle
    /// 二级标题（如 Navigation Title）
    case title
    /// 三级标题（如卡片标题、表单 Section 标题）
    case headline
    /// 正文
    case body
    /// 副文 / 说明
    case caption
    /// 大数字（统计页）
    case stat

    var font: Font {
        switch self {
        case .largeTitle: return .system(.largeTitle, design: .serif).weight(.regular)
        case .title:      return .system(.title2, design: .serif).weight(.regular)
        case .headline:   return .system(.headline, design: .serif).weight(.medium)
        case .body:       return .system(.body, design: .default)
        case .caption:    return .system(.caption, design: .default)
        case .stat:       return .system(.largeTitle, design: .serif).weight(.light)
        }
    }

    /// 字间距（tracking）。中文排版中适度 tracking 提升呼吸感和高级感。
    var tracking: CGFloat {
        switch self {
        case .largeTitle: return 1.5
        case .title:      return 1.2
        case .headline:   return 0.8
        case .body:       return 0.3
        case .caption:    return 0.8
        case .stat:       return 1.0
        }
    }
}

extension View {
    /// 应用告别清单字体 token（font + tracking 一次到位）。
    func appFont(_ typography: AppTypography) -> some View {
        self
            .font(typography.font)
            .tracking(typography.tracking)
    }
}
