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
        // 显式 set nil 比 removePersistentDomain 更可靠（模拟器上 remove 可能有缓存延迟）
        // 同时 reset store 同名
        UserDefaults.standard.set(nil, forKey: "app.themeMode")
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
