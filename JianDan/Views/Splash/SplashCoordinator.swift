import SwiftUI

/// 开屏短文协调器：管理「可见性 + 计时 + 跳过 + 进度」四件事
///
/// 设计原则：
/// - **冷启动触发**：进程启动时由 `JianDanApp` 注入 `quote` 后立即开始展示
/// - **5 秒自动淡出**：使用 SwiftUI `.task(id:)` 配合 sleep 实现，超时可跳过
/// - **点击任意位置立即淡出**：蒙层透明 Button 覆盖在最顶层
/// - **重复启动不重置**：淡出后即便 quote 变化也不再展示（避免动画反复触发）
/// - **倒计时进度**：通过 `remainingFraction` 暴露 1.0→0.0 进度，供 UI 层展示环形指示器
///
/// 状态机：
/// - `isVisible = true` → 显示，5s 计时开始
/// - 5s 倒计时结束 / 用户点击 → `isVisible = false`（不可逆）
/// - opacity 与 `isVisible` 绑定；淡出完成后 SplashQuoteView 整体从 hierarchy 移除
///
/// iOS 17+ 使用 `@Observable`，与项目其他状态对象保持一致。
@Observable
final class SplashCoordinator {
    /// 是否仍可见（true → 显示；false → 已淡出并移除）
    private(set) var isVisible: Bool

    /// 当前展示的短文（构造时锁定，启动期间不变）
    let quote: Wisdom

    /// 自动淡出秒数（默认 5s；测试可注入更短的值）
    let autoDismissSeconds: TimeInterval

    /// 已流逝秒数（从 init 开始累加，用于进度指示器）
    private(set) var elapsed: TimeInterval = 0

    /// 剩余比例 1.0→0.0（给 UI 层做环形进度条使用）
    var remainingFraction: Double {
        max(0, 1 - elapsed / max(autoDismissSeconds, 1))
    }

    /// 驱动 `elapsed` 递增的计时器（精确到 ~50ms）
    @ObservationIgnored
    private var progressTimer: Timer?

    init(quote: Wisdom, autoDismissSeconds: TimeInterval = 5.0) {
        self.quote = quote
        self.autoDismissSeconds = autoDismissSeconds
        self.isVisible = true
        startProgressTimer()
    }

    deinit {
        progressTimer?.invalidate()
    }

    /// 外部调用：跳过开屏（点击 / 自动倒计时结束都会调这个）
    func dismiss() {
        guard isVisible else { return }
        isVisible = false
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Private

    /// 启动一个 ~50ms 间隔的 Timer 在主线程累加 `elapsed`
    /// 每次累加触发 `@Observable` 更新，驱动 UI 层进度条重绘。
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { [weak self] _ in
            guard let self, self.isVisible else { return }
            self.elapsed += 0.05
        }
    }
}

/// SplashCoordinator 的 SwiftUI 容器：把可见性 + 计时 + 点击统一封装
///
/// 使用：
/// ```swift
/// SplashContainer(coordinator: optionalCoordinator) {
///     RootTabView()
/// }
/// ```
///
/// 行为：
/// - `coordinator == nil`：完全跳过开屏，无任何开销
/// - `coordinator != nil`：透明度 0→1 入场（0.4s），5s 后或被点击后 1→0 出场（0.4s）
/// - 出场动画完成后，整体从 hierarchy 卸载（避免遮挡 Tab 交互）
///
/// 回调：
/// - `onDismiss`：在 splash 真正消失时（点击 dismiss / 自动倒计时结束 / 从未展示）触发一次，
///   让下游（如 DiaryView 的 stagger 入场）等待合适时机再开始。
///
/// 设计注意：
/// - 直接读取传入的 `coordinator`（不内部 State 化），因为父视图的 `@State` 在 body
///   第一次求值时是 nil。如果容器用 State 镜像初始值，后续父视图变化不会传进来。
/// - 计时 `.task` 和点击 dismiss 都直接操作同一 coordinator 实例。
struct SplashContainer<Content: View>: View {
    @Environment(LanguageManager.self) private var languageManager
    let coordinator: SplashCoordinator?
    var onDismiss: () -> Void = {}
    @ViewBuilder var content: () -> Content

    init(
        coordinator: SplashCoordinator?,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.coordinator = coordinator
        self.onDismiss = onDismiss
        self.content = content
    }

    var body: some View {
        content()
            .overlay {
                if let coordinator, coordinator.isVisible {
                    SplashQuoteView(
                        quote: coordinator.quote,
                        language: languageManager.language,
                        remainingFraction: coordinator.remainingFraction
                    )
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        // 点击 splash 时立即 dismiss；只有 splash 可见时拦截 tap
                        // —— splash 不可见后不再挂 .onTapGesture，让 NavigationLink
                        // 等内层 hit test 正常命中。
                        .onTapGesture {
                            coordinator.dismiss()
                            onDismiss()
                        }
                        .task(id: ObjectIdentifier(coordinator)) {
                            // 每个 coordinator 实例只跑一次倒计时
                            // ObjectIdentifier 保证：coordinator 不变就不会重启 task
                            guard coordinator.isVisible else { return }
                            try? await Task.sleep(
                                nanoseconds: UInt64(coordinator.autoDismissSeconds * 1_000_000_000)
                            )
                            coordinator.dismiss()
                            onDismiss()
                        }
                } else {
                    // 无 splash（-disableSplash）或已 dismiss 后：
                    // 触发一次 onDismiss 让下游不等。
                    // onAppear 在此条件稳定期间只触发一次，不会重复。
                    Color.clear
                        .onAppear { onDismiss() }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: coordinator?.isVisible)
    }
}

#Preview {
    SplashContainer(coordinator: SplashCoordinator(
        quote: WisdomLibrary.all[0],
        autoDismissSeconds: 3.0
    )) {
        // 模拟主界面：仅展示「告别清单」两字以便对比叠加效果
        ZStack {
            Color.white
            Text("主界面")
                .font(.largeTitle)
        }
        .ignoresSafeArea()
    }
    .environment(\.appTheme, AppTheme(mode: .light))
}
