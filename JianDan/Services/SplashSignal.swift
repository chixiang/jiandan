import Foundation

/// 标志 Splash 是否已经结束
///
/// Splash 持续期间 DiaryView 不做错峰入场（因为不可见）；
/// 当 splash 真正消失后才触发 staggered fade-in。
///
/// 用法：
/// ```swift
/// @Environment(SplashSignal.self) private var splashSignal
///
/// .task(id: splashSignal.didDismiss) {
///     if splashSignal.didDismiss {
///         withAnimation { didEnter = true }
///     }
/// }
/// ```
///
/// `.task(id:)` 在视图首次出现 + id 变化时都会触发：
/// - 冷启动：首次出现时 `didDismiss = false` 不触发；splash 结束后变 true 触发
/// - `-disableSplash`：`didDismiss` 立即为 true，首次出现就触发
@Observable
final class SplashSignal {
    var didDismiss: Bool = false
}