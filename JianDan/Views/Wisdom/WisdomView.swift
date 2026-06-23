import SwiftUI

/// 「极简」Tab：古典文人金句列表（Phase 1 内置静态内容）
struct WisdomView: View {
    @Environment(\.appTheme) private var theme
    private let wisdoms = WisdomLibrary.all

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(wisdoms) { wisdom in
                        NavigationLink(value: wisdom) {
                            WisdomCardView(wisdom: wisdom)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.background)
            .navigationTitle("极简")
            .navigationDestination(for: Wisdom.self) { wisdom in
                WisdomDetailView(wisdom: wisdom)
            }
        }
    }
}

#Preview {
    WisdomView()
        .environment(\.appTheme, AppTheme(mode: .light))
}