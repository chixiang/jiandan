import SwiftUI

/// 骨架屏 shimmer 动效：从左到右的渐变扫光
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.25)),
                            .init(color: .white.opacity(0.3), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.25)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 1.5)
                    .offset(x: proxy.size.width * phase)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    /// 叠加 shimmer 扫光动效，用于图片 / 内容加载占位
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
