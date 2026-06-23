import SwiftUI

/// 金句详情页：大字显示全文 + 出处
struct WisdomDetailView: View {
    @Environment(\.appTheme) private var theme
    let wisdom: Wisdom

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // 顶部引号装饰
                Text("\u{201C}")
                    .font(.system(size: 96, weight: .ultraLight, design: .serif))
                    .foregroundStyle(theme.accent.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 金句全文（衬线大字，留白充足）
                Text(wisdom.text)
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(theme.primaryText)
                    .lineSpacing(12)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // 装饰分隔线
                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 0.5)
                    .padding(.vertical, 8)

                // 出处
                HStack(spacing: 6) {
                    Text("—")
                        .font(AppTypography.body)
                        .foregroundStyle(theme.secondary)
                    Text(wisdom.attribution)
                        .font(AppTypography.body)
                        .foregroundStyle(theme.secondary)
                }

                // 可选分类标签
                if let category = wisdom.category {
                    Text(category)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(theme.accent.opacity(0.12))
                        )
                }

                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .background(theme.background)
        .navigationTitle("极简")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WisdomDetailView(wisdom: WisdomLibrary.all[0])
    }
    .environment(\.appTheme, AppTheme(mode: .light))
}