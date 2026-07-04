import SwiftUI

/// 开屏短文画面：纯静态视觉组件
///
/// 设计原则：
/// - **克制到极致**：仅展示一句金句 + 出处 + 底部「告别清单」二字水印，无任何图标 / 按钮
/// - **垂直留白**：顶部 ~22% 留白、中段金句、底部 ~14% 水印，居中对齐
/// - **逐字出现**：金句文字以 ~30ms/字的速度逐个淡入，出处紧随其后
/// - **状态外置**：是否可见、是否跳过都由调用方（`SplashCoordinator`）管理
/// - **倒计时进度**：通过 `remainingFraction` 展示极细环形进度条，不干扰金句阅读
///
/// 动效：金句逐字出现（opacity 0→1 + 微上移 2pt），整体容器过渡由 SplashCoordinator 控制。
struct SplashQuoteView: View {
    @Environment(\.appTheme) private var theme
    let quote: Wisdom
    let language: AppLanguage
    /// 倒计时剩余比例 1.0→0.0，用于环形进度指示器
    let remainingFraction: Double

    /// 已揭示的字数（逐字推进）
    @State private var revealedCount = 0
    /// 出处是否已显示（金句全揭示后显示）
    @State private var showAttribution = false

    /// 每字间隔：CJK（中/日）逐字慢速，拉丁语系快速
    private var revealInterval: TimeInterval {
        switch language {
        case .zhHans, .ja: return 0.06
        default:           return 0.03
        }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部 ~22% 留白
                Spacer().frame(height: screenHeightFraction(0.22))

                // 中段：金句 + 出处
                quoteBlock

                Spacer()  // 中段与底部水印之间用弹性留白分隔

                // 底部：极克制「告别清单」水印 + 倒计时环形进度
                VStack(spacing: 6) {
                    // 环形进度指示器：从顶部分别向两侧缩短，剩余比例 1.0→0.0
                    Circle()
                        .trim(from: 0, to: remainingFraction)
                        .stroke(theme.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 20, height: 20)

                    Text("告别清单")
                        .font(AppTypography.caption.font)
                        .tracking(8)
                        .foregroundStyle(theme.secondary.opacity(0.55))
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 40)
        }
        .onAppear(perform: startReveal)
        // 不合并 accessibility：UI test 需要按文本分别断言金句和出处
    }

    /// 金句 + 出处区块
    private var quoteBlock: some View {
        VStack(spacing: 20) {
            // 逐字出现的金句（使用 AttributedString 支持换行）
            revealedText(quote.localizedText(for: language))
                .appFont(.headline)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            // 出处（金句全揭示后淡入）
            if showAttribution {
                Text("— \(quote.localizedAttribution(for: language))")
                    .font(AppTypography.caption.font)
                    .foregroundStyle(theme.secondary)
                    .tracking(1)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 逐字构建文本：使用 AttributedString 保留换行能力
    private func revealedText(_ text: String) -> Text {
        var attr = AttributedString(text)
        for (index, _) in attr.characters.enumerated() {
            let start = attr.index(attr.startIndex, offsetByCharacters: index)
            let end = attr.index(afterCharacter: start)
            attr[start..<end].foregroundColor = index < revealedCount
                ? theme.primaryText
                : theme.primaryText.opacity(0)
        }
        return Text(attr)
    }

    /// 启动逐字计时器
    private func startReveal() {
        let text = quote.localizedText(for: language)
        let total = text.count
        guard total > 0 else { return }

        revealedCount = 0
        showAttribution = false

        for i in 0..<total {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * revealInterval) {
                withAnimation(.easeOut(duration: 0.15)) {
                    revealedCount = i + 1
                }
                // 最后一个字揭示后，显示出处
                if i == total - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showAttribution = true
                        }
                    }
                }
            }
        }
    }

    /// 计算屏幕高度的固定比例（用于顶部留白）
    /// 使用 `UIScreen.main.bounds.height` 规避 GeometryReader 嵌套带来的复杂性
    private func screenHeightFraction(_ fraction: CGFloat) -> CGFloat {
        UIScreen.main.bounds.height * fraction
    }
}

#Preview("Light") {
    SplashQuoteView(quote: WisdomLibrary.all[0], language: .system, remainingFraction: 1.0)
        .environment(\.appTheme, AppTheme(mode: .light))
}

#Preview("Ink") {
    SplashQuoteView(quote: WisdomLibrary.all[1], language: .system, remainingFraction: 0.6)
        .environment(\.appTheme, AppTheme(mode: .ink))
}
