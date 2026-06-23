import SwiftUI

/// 每日一句：WisdomView 顶部的大卡片
///
/// 数据来自 `QuoteRepository.todayQuote(for:)`，基于「年内第几天」选句。
/// 风格：左侧朱砂色装饰条 + 衬线大字金句 + 灰色出处
struct DailyQuoteView: View {
    @Environment(\.appTheme) private var theme
    let quote: Wisdom

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧装饰条
            Rectangle()
                .fill(theme.accent)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 12) {
                // 「今日一句」标签
                Text("今日一句")
                    .font(AppTypography.caption)
                    .foregroundStyle(theme.accent)
                    .tracking(2)  // 字间距拉开，更雅致

                // 金句大字
                Text(quote.text)
                    .font(AppTypography.headline)
                    .foregroundStyle(theme.primaryText)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // 出处
                HStack(spacing: 6) {
                    Text("—")
                    Text(quote.attribution)
                }
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日一句：\(quote.text)，\(quote.attribution)")
    }
}

#Preview {
    let theme = AppTheme(mode: .light)
    return DailyQuoteView(quote: WisdomLibrary.all[0])
        .padding()
        .background(theme.background)
        .environment(\.appTheme, theme)
}