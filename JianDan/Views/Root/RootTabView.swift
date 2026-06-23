import SwiftUI

/// 根 Tab 容器：三个主分区
///
/// 注意：不要在此处覆盖 .tint —— 让 `JianDanApp` 的 `.appTheme(...)` 注入主题相关 tint。
/// 之前硬编码 `.tint(Color("AccentColor"))` 会导致 Ink 模式下 tint 错误（Asset Catalog
/// 缺少 Ink 分支，系统回退到 dark 分支的淡青色，而非 AppColors.Ink.accent 的朱砂）。
struct RootTabView: View {
    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("减单", systemImage: "leaf")
                }

            WisdomView()
                .tabItem {
                    Label("极简", systemImage: "book.closed")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
    }
}

#Preview {
    RootTabView()
}