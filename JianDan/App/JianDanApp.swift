import SwiftUI
import SwiftData

@main
struct JianDanApp: App {
    @State private var themeManager = ThemeManager()
    @State private var currencyManager = CurrencyManager()
    @State private var languageManager = LanguageManager()

    /// 开屏短文协调器：冷启动时随机选一条
    ///
    /// 仅在真冷启动时显示（`ScenePhase` 从 `.background` → `.active` 不算冷启动）。
    /// 通过 `@State` 持有，进程生命周期内不变；从后台回前台时 coordinator 实例仍在，
    /// 但 `isVisible` 已是 false（5s 内已自动淡出），不会重新展示。
    ///
    /// 声明时立即初始化，确保 body 首次渲染时 coordinator 已就位，避免列表画面先闪现。
    @State private var splashCoordinator: SplashCoordinator? = Self.makeSplashCoordinator()

    /// 启动时检测 launch arguments；UI 测试可通过 `-resetStore` 清空 SwiftData store，
    /// 或 `-resetUserDefaults` 清空 UserDefaults（包括主题选择等持久化状态）。
    private static func shouldResetStore() -> Bool {
        ProcessInfo.processInfo.arguments.contains("-resetStore")
    }

    private static func shouldResetUserDefaults() -> Bool {
        ProcessInfo.processInfo.arguments.contains("-resetUserDefaults")
    }

    private static func resetStoreIfNeeded() {
        guard shouldResetStore() else { return }
        let fm = FileManager.default
        let supportDir = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        guard let supportDir else { return }
        for filename in ["default.store", "default.store-shm", "default.store-wal"] {
            let url = supportDir.appendingPathComponent(filename)
            try? fm.removeItem(at: url)
        }
    }

    private static func resetUserDefaultsIfNeeded() {
        guard shouldResetUserDefaults() else { return }
        // 显式 set nil 比 removePersistentDomain 更可靠（模拟器上 remove 可能有缓存延迟）
        // 同时 reset store 同名
        UserDefaults.standard.set(nil, forKey: "app.themeMode")
        UserDefaults.standard.set(nil, forKey: "app.currency")
        UserDefaults.standard.set(nil, forKey: "app.language")
    }

    /// -seedTestData launch arg 触发：清空 store 后自动填充样本记录
    /// 注意：internal 而非 private，供 RootTabView.onAppear 调用
    static func seedTestDataIfNeeded(context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-seedTestData") else { return }
        let importer = DataImporter(context: context)
        let result = importer.importSampleRecords()
        if let err = result.error {
            print("[SeedData] 导入失败: \(err)")
        } else {
            print("[SeedData] 已导入 \(result.imported) 条，跳过 \(result.skipped) 条")
        }
    }

    /// UI 测试可注入短文：用 launch arg `-splashQuoteId <id>` 锁定指定 id 的短文
    /// 测试可注入更短的自动淡出秒数：`-splashAutoDismiss <seconds>`
    private static func makeSplashCoordinator() -> SplashCoordinator? {
        // 测试 launch arg：完全关闭开屏
        if ProcessInfo.processInfo.arguments.contains("-disableSplash") {
            return nil
        }
        let repository = QuoteRepository()
        let args = ProcessInfo.processInfo.arguments

        let quote: Wisdom?
        if let idIndex = args.firstIndex(of: "-splashQuoteId"),
           idIndex + 1 < args.count {
            let targetId = args[idIndex + 1]
            quote = repository.all.first(where: { $0.id == targetId })
        } else {
            quote = repository.randomQuote()
        }

        guard let quote else { return nil }

        // 测试 launch arg：注入更短的淡出秒数（默认 5s）
        var autoDismiss: TimeInterval = 5.0
        if let secIndex = args.firstIndex(of: "-splashAutoDismiss"),
           secIndex + 1 < args.count,
           let secs = Double(args[secIndex + 1]) {
            autoDismiss = secs
        }

        return SplashCoordinator(quote: quote, autoDismissSeconds: autoDismiss)
    }

    var body: some Scene {
        WindowGroup {
            SplashContainer(coordinator: splashCoordinator) {
                RootTabView()
                    .appTheme(themeManager.mode)
                    .environment(themeManager)
                    .environment(currencyManager)
            }
            .environment(languageManager)
        }
        .modelContainer(for: [FarewellRecord.self, UserCategory.self])
    }

    init() {
        Self.resetStoreIfNeeded()
        Self.resetUserDefaultsIfNeeded()
    }
}
