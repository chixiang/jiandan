import SwiftUI
import SwiftData

@main
struct JianDanApp: App {
    @State private var themeManager = ThemeManager()

    /// 启动时检测 launch arguments；UI 测试可通过 `-resetStore` 清空 SwiftData store。
    private static func shouldResetStore() -> Bool {
        ProcessInfo.processInfo.arguments.contains("-resetStore")
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
    }
}
