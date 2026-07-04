import CoreGraphics

/// 告别清单间距规范：5 档 + 两个语义别名
///
/// 用法：优先用 `AppSpacing` 命名常量；`.padding` / `VStack(spacing:)` / `HStack(spacing:)`
/// 等需要 `CGFloat` 的场景可以用同名 `CGFloat.xs / .sm / .md / .lg / .xl` 简写。
///
/// 5 档足以覆盖「克制」基调下的全部场景：8 / 12 / 16 / 24 / 32。
///
/// 语义别名：
/// - `screenPadding`: 页面水平边距（List / ScrollView / VStack 的左右）
/// - `listItemSpacing`: 列表卡片之间的间距（介于 `.sm` 和 `.md` 之间）
enum AppSpacing {
    /// 紧凑（8）：分组内 chip / icon 周边距
    static let xs: CGFloat = 8
    /// 小（12）：section 内堆叠元素之间
    static let sm: CGFloat = 12
    /// 中（16）：默认卡内 padding、卡片横向 stack 间距
    static let md: CGFloat = 16
    /// 大（24）：section 之间、空态元素之间
    static let lg: CGFloat = 24
    /// 超大（32）：页面级分隔（底部留白、大按钮高度）
    static let xl: CGFloat = 32

    /// 页面水平边距。List / ScrollView / VStack 左右统一用此值。
    static let screenPadding: CGFloat = 20

    /// 列表卡片之间的间距（介于 `.sm` 与 `.md` 之间，给卡片轻微分离感）。
    static let listItemSpacing: CGFloat = 14
}

extension CGFloat {
    /// 间距简写，让 `.padding(.md)` / `VStack(spacing: .lg)` 直接可用
    static let xs = AppSpacing.xs
    static let sm = AppSpacing.sm
    static let md = AppSpacing.md
    static let lg = AppSpacing.lg
    static let xl = AppSpacing.xl
    static let screenPadding = AppSpacing.screenPadding
    static let listItemSpacing = AppSpacing.listItemSpacing
}