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
        VStack(alignment: .leading, spacing: 16) {
            Text("统计")
                .appFont(.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
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

            HStack(spacing: 12) {
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
                    ForEach(stats.categoryBreakdown, id: \.category) { item in
                        BreakdownRow(
                            icon: item.category.iconName,
                            label: item.category.displayName,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.categoryBreakdown.first?.count ?? 1
                        )
                    }
                }
            }

            if !stats.categoryPriceBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "分类总价")) {
                    ForEach(stats.categoryPriceBreakdown, id: \.category) { item in
                        BreakdownRow(
                            icon: item.category.iconName,
                            label: item.category.displayName,
                            value: priceString(item.totalPrice),
                            count: Int(item.totalPrice),
                            maxCount: Int(stats.categoryPriceBreakdown.first?.totalPrice ?? 0)
                        )
                    }
                }
            }

            if !stats.methodBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "去向分布")) {
                    ForEach(Array(stats.methodBreakdown.enumerated()), id: \.offset) { _, item in
                        BreakdownRow(
                            icon: item.icon,
                            label: item.name,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.methodBreakdown.first?.count ?? 1
                        )
                    }
                }
            }

            if !stats.emotionBreakdown.isEmpty {
                BreakdownCard(title: String(localized: "情感分布")) {
                    ForEach(stats.emotionBreakdown, id: \.stars) { item in
                        BreakdownRow(
                            icon: nil,
                            label: item.name,
                            value: "\(item.count)",
                            count: item.count,
                            maxCount: stats.emotionBreakdown.first?.count ?? 1
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
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

private struct BreakdownCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .appFont(.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)
            content
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

    @Environment(\.appTheme) private var theme
}

private struct BreakdownRow: View {
    @Environment(\.appTheme) private var theme
    let icon: String?
    let label: String
    let value: String
    let count: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
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
                let ratio = maxCount > 0 ? Double(count) / Double(maxCount) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.divider)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.accent)
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 6)

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
