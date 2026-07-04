import SwiftUI

/// 根 Tab 容器：三个主分区
///
/// 注意：不要在此处覆盖 .tint —— 让 `JianDanApp` 的 `.appTheme(...)` 注入主题相关 tint。
/// 之前硬编码 `.tint(Color("AccentColor"))` 会导致 Ink 模式下 tint 错误（Asset Catalog
/// 缺少 Ink 分支，系统回退到 dark 分支的淡青色，而非 AppColors.Ink.accent 的朱砂）。
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DiaryView()
                    .tabItem {
                        Label("告别清单", systemImage: selectedTab == 0 ? "leaf.fill" : "leaf")
                    }
                    .tag(0)

                RemembranceView()
                    .tabItem {
                        Label("怀念", systemImage: selectedTab == 1 ? "heart.fill" : "heart")
                    }
                    .tag(1)

                ProfileView()
                    .tabItem {
                        Label("我的", systemImage: selectedTab == 2 ? "person.fill" : "person")
                    }
                    .tag(2)
            }
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .sensoryFeedback(.selection, trigger: selectedTab)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: selectedTab)
        }
        .animation(.easeInOut(duration: 0.6), value: theme.background)
        .onAppear {
            // -seedTestData launch arg：模拟器/真机开发测试用
            JianDanApp.seedTestDataIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    RootTabView()
}