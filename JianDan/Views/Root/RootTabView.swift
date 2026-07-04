import SwiftUI

/// 根 Tab 容器：三个主分区
///
/// 注意：不要在此处覆盖 .tint —— 让 `JianDanApp` 的 `.appTheme(...)` 注入主题相关 tint。
/// 之前硬编码 `.tint(Color("AccentColor"))` 会导致 Ink 模式下 tint 错误（Asset Catalog
/// 缺少 Ink 分支，系统回退到 dark 分支的淡青色，而非 AppColors.Ink.accent 的朱砂）。
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DiaryView()
                .tabItem {
                    Label("告别清单", systemImage: "leaf")
                }
                .tag(0)

            RemembranceView()
                .tabItem {
                    Label("怀念", systemImage: "heart")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
                .tag(2)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .symbolEffect(.bounce, value: selectedTab)
        .onAppear {
            // -seedTestData launch arg：模拟器/真机开发测试用
            JianDanApp.seedTestDataIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    RootTabView()
}