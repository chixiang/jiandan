import SwiftUI
import SwiftData

@main
struct JianDanApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .appTheme(themeManager.mode)
                .environment(themeManager)
        }
        .modelContainer(for: FarewellRecord.self)
    }
}
