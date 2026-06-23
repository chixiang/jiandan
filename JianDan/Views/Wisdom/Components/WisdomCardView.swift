import SwiftUI

/// 金句卡片（列表行样式）：节选 + 出处
struct WisdomCardView: View {
    @Environment(\.appTheme) private var theme
    let wisdom: Wisdom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 金句正文（节选；详情页看全文）
            Text(wisdom.text)
                .font(AppTypography.headline)
                .foregroundStyle(theme.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // 出处 + 可选分类
            HStack(spacing: 8) {
                Text(wisdom.attribution)
                    .font(AppTypography.caption)
                    .foregroundStyle(theme.secondary)

                if let category = wisdom.category {
                    Text(category)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(theme.accent.opacity(0.12))
                        )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }
}

#Preview {
    let theme = AppTheme(mode: .light)
    return VStack(spacing: 12) {
        WisdomCardView(wisdom: WisdomLibrary.all[0])
        WisdomCardView(wisdom: WisdomLibrary.all[4])
    }
    .padding()
    .background(theme.background)
    .environment(\.appTheme, theme)
}