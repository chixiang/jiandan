import SwiftUI

/// 「极简」Tab：每日一句 + 古典文人金句列表
///
/// - 顶部：`DailyQuoteView`，根据当日 hash 选一句
/// - 列表：`QuoteRepository` 提供的全量短文（来自 daily_quotes.json）
struct WisdomView: View {
    @Environment(\.appTheme) private var theme

    /// 短文仓库（lazy 创建；Phase 2 可改为 @Environment 注入便于测试）
    private let repository = QuoteRepository()

    private var allQuotes: [Wisdom] { repository.all }
    private var todayQuote: Wisdom? { repository.todayQuote() }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 顶部：今日一句（如果库为空则不显示）
                    if let quote = todayQuote {
                        DailyQuoteView(quote: quote)
                            .padding(.bottom, 4)
                    }

                    // 列表标题
                    HStack {
                        Text("全部短文")
                            .font(AppTypography.caption)
                            .foregroundStyle(theme.secondary)
                            .tracking(2)
                        Spacer()
                    }
                    .padding(.top, 8)

                    // 全量列表
                    ForEach(allQuotes) { wisdom in
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