import SwiftUI

/// 根 Tab 容器：三个主分区
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
        .tint(Color("AccentColor"))  // 使用 Assets.xcassets/AccentColor
    }
}

#Preview {
    RootTabView()
}