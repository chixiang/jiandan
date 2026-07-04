import SwiftUI

/// 按压时的轻微缩放 + 透明度反馈
///
/// 用于 `NavigationLink` / `Button` 等可点击区域，让按下时有"被按住"的物理感。
/// 默认 `0.97` 缩放、`0.9` 透明度，符合 App 的克制基调。
///
/// 用法：
/// ```swift
/// NavigationLink(value: record) { ... }
///     .buttonStyle(PressScaleButtonStyle())
/// ```
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var pressedOpacity: Double = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}