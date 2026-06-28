import SwiftUI

/// 开屏短文画面：纯静态视觉组件
///
/// 设计原则：
/// - **克制到极致**：仅展示一句金句 + 出处 + 底部「告别清单」二字水印，无任何图标 / 按钮
/// - **垂直留白**：顶部 ~22% 留白、中段金句、底部 ~14% 水印，居中对齐
/// - **状态外置**：是否可见、是否跳过都由调用方（`SplashCoordinator`）管理
///
/// 动效：仅 opacity 0→1 / 1→0（0.4s ease-in-out），由 SplashCoordinator 控制，
/// 本视图不持有任何 `@State` / `@StateObject`。
struct SplashQuoteView: View {
    @Environment(\.appTheme) private var theme
    let quote: Wisdom

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部 ~22% 留白
                Spacer().frame(height: screenHeightFraction(0.22))

                // 中段：金句 + 出处
                quoteBlock

                Spacer()  // 中段与底部水印之间用弹性留白分隔

                // 底部：极克制「告别清单」水印
                Text("告别清单")
                    .font(AppTypography.caption)
                    .tracking(8)  // 字间距拉开
                    .foregroundStyle(theme.secondary.opacity(0.55))
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 40)
        }
        // 不合并 accessibility：UI test 需要按文本分别断言金句和出处
    }

    /// 金句 + 出处区块
    private var quoteBlock: some View {
        VStack(spacing: 20) {
            Text(quote.text)
                .font(AppTypography.headline)  // 衬线大字
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.attribution)")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    /// 计算屏幕高度的固定比例（用于顶部留白）
    /// 使用 `UIScreen.main.bounds.height` 规避 GeometryReader 嵌套带来的复杂性
    private func screenHeightFraction(_ fraction: CGFloat) -> CGFloat {
        UIScreen.main.bounds.height * fraction
    }
}

#Preview("Light") {
    SplashQuoteView(quote: WisdomLibrary.all[0])
        .environment(\.appTheme, AppTheme(mode: .light))
}

#Preview("Ink") {
    SplashQuoteView(quote: WisdomLibrary.all[1])
        .environment(\.appTheme, AppTheme(mode: .ink))
}
