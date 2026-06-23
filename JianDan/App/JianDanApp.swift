import SwiftUI
import SwiftData

@main
struct JianDanApp: App {
    @State private var themeManager = ThemeManager()

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
        // 测试阶段清空 standard suite；用 bundleIdentifier 隔离避免影响其它 app
        let suiteName = Bundle.main.bundleIdentifier ?? "com.jiandan.app"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .appTheme(themeManager.mode)
                .environment(themeManager)
        }
        .modelContainer(for: FarewellRecord.self)
    }

    init() {
        Self.resetStoreIfNeeded()
        Self.resetUserDefaultsIfNeeded()
    }
}
