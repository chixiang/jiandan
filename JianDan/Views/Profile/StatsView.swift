import SwiftUI

/// 告别统计卡片网格
///
/// 展示告别数 / 平均陪伴 / 最长陪伴 / 总价等关键指标。
/// 下方依次展示分类分布、分类总价、去向分布、情感分布。
struct StatsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(CurrencyManager.self) private var currencyManager
    let stats: FarewellStats

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text("统计")
                .font(AppTypography.caption.font)
                .foregroundStyle(theme.secondary)
                .tracking(2)
                .padding(.horizontal, .xs)

            HStack(spacing: .sm) {
                StatCard(
                    value: "\(stats.totalCount)",
                    label: String(localized: "告别数"),
                    icon: "leaf.fill"
                )
                StatCard(
                    value: stats.averageCompanionshipDays.map { "\($0)" } ?? "—",
                    label: String(localized: "平均陪伴"),
                    icon: "heart.fill"
                )
            }

            HStack(spacing: .sm) {
                StatCard(
                    value: "\(stats.longestCompanionshipDays)",
                    label: String(localized: "最长陪伴"),
                    icon: "hourglass"
                )
                StatCard(
                    value: priceString(stats.totalPurchasePrice),
                    label: String(localized: "总价"),
                    icon: currencyManager.currency.iconCircle
                )
            }

            if !stats.categoryBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "分类分布")) {
                    ForEach(Array(stats.categoryBreakdown.enumerated()), id: \.element.category) { offset, item in
                        BreakdownRow(
                            icon: item.category.iconName,
                            label: item.category.displayName,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.categoryBreakdown.first?.count ?? 1,
                            index: offset
                        )
                    }
                }
            }

            if !stats.categoryPriceBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "分类总价")) {
                    ForEach(Array(stats.categoryPriceBreakdown.enumerated()), id: \.element.category) { offset, item in
                        BreakdownRow(
                            icon: item.category.iconName,
                            label: item.category.displayName,
                            value: priceString(item.totalPrice),
                            count: Int(item.totalPrice),
                            maxCount: Int(stats.categoryPriceBreakdown.first?.totalPrice ?? 0),
                            index: offset
                        )
                    }
                }
            }

            if !stats.methodBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "去向分布")) {
                    ForEach(Array(stats.methodBreakdown.enumerated()), id: \.offset) { offset, item in
                        BreakdownRow(
                            icon: item.icon,
                            label: item.name,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.methodBreakdown.first?.count ?? 1,
                            index: offset
                        )
                    }
                }
            }

            if !stats.emotionBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "情感分布")) {
                    ForEach(Array(stats.emotionBreakdown.enumerated()), id: \.element.stars) { offset, item in
                        BreakdownRow(
                            icon: nil,
                            label: item.name,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.emotionBreakdown.first?.count ?? 1,
                            index: offset
                        )
                    }
                }
            }
        }
    }

    private func priceString(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "\(currencyManager.currency.symbol)%.1fk", price / 1000)
        }
        if price == 0 {
            return "—"
        }
        return "\(currencyManager.currency.symbol)\(String(format: "%.0f", price))"
    }
}

// MARK: - 组件

private struct StatCard: View {
    @Environment(\.appTheme) private var theme
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            HStack(spacing: .xs) {
                Image(systemName: icon)
                    .appFont(.caption)
                    .foregroundStyle(theme.accent)
                Text(label)
                    .appFont(.caption)
                    .foregroundStyle(theme.secondary)
            }

            Text(value)
                .appFont(.stat)
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }
}

private struct BreakdownCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(title)
                .font(AppTypography.caption.font)
                .foregroundStyle(theme.secondary)
                .tracking(2)
            content
        }
        .padding(.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }

    @Environment(\.appTheme) private var theme
}

private struct BreakdownRow: View {
    @Environment(\.appTheme) private var theme
    let icon: String?
    let label: String
    let value: String
    let count: Int
    let maxCount: Int
    let index: Int

    @State private var animated = false

    var body: some View {
        HStack(spacing: .sm) {
            HStack(spacing: .xs) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .frame(width: 16)
                } else {
                    Color.clear
                        .frame(width: 16)
                }
                Text(label)
                    .lineLimit(1)
            }
            .appFont(.caption)
            .foregroundStyle(theme.primaryText)
            .frame(width: 100, alignment: .leading)

            GeometryReader { proxy in
                let ratio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0 as CGFloat
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.divider)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.accent)
                        .frame(width: animated ? proxy.size.width * ratio : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7)
                            .delay(Double(index) * 0.06), value: animated)
                }
            }
            .frame(height: 6)
            .onAppear {
                animated = true
            }

            Text(value)
                .appFont(.caption)
                .foregroundStyle(theme.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }
}

// MARK: - Previews

#Preview("累计") {
    let theme = AppTheme(mode: .light)
    let stats = FarewellStats(
        totalCount: 12,
        averageCompanionshipDays: 70,
        longestCompanionshipDays: 365,
        totalPurchasePrice: 1280,
        categoryBreakdown: [
            CategoryCount(category: .builtin(.clothing), count: 5),
            CategoryCount(category: .builtin(.books), count: 3),
            CategoryCount(category: .builtin(.electronics), count: 2),
            CategoryCount(category: .builtin(.other), count: 2),
        ],
        categoryPriceBreakdown: [
            CategoryPriceCount(category: .builtin(.clothing), totalPrice: 6400),
            CategoryPriceCount(category: .builtin(.electronics), totalPrice: 3200),
        ],
        methodBreakdown: [
            MethodCount(name: "捐赠", icon: "heart", count: 4),
            MethodCount(name: "送人", icon: "gift", count: 3),
            MethodCount(name: "扔掉", icon: "trash", count: 2),
        ],
        emotionBreakdown: [
            EmotionCount(stars: 2, name: "不舍", count: 5),
            EmotionCount(stars: 3, name: "复杂", count: 3),
            EmotionCount(stars: 1, name: "平静", count: 1),
        ]
    )
    return ScrollView {
        StatsView(stats: stats)
            .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}

#Preview("空态") {
    let theme = AppTheme(mode: .light)
    return ScrollView {
        StatsView(stats: FarewellStats(
            totalCount: 0,
            averageCompanionshipDays: nil,
            longestCompanionshipDays: 0,
            totalPurchasePrice: 0,
            categoryBreakdown: [],
            categoryPriceBreakdown: [],
            methodBreakdown: [],
            emotionBreakdown: []
        ))
        .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}
