import SwiftUI

/// 告别统计卡片网格
///
/// 展示告别数 / 平均陪伴 / 最长陪伴 / 总价等关键指标。
/// 数据由 `StatsCalculator.compute(from:)` 提供；本 View 只负责渲染。
struct StatsView: View {
    @Environment(\.appTheme) private var theme
    let stats: FarewellStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("统计")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.totalCount)",
                    label: "告别数",
                    icon: "leaf.fill"
                )
                StatCard(
                    value: stats.averageCompanionshipDays.map { String(format: "%.1f", $0) } ?? "—",
                    label: "平均陪伴",
                    icon: "heart.fill"
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.longestCompanionshipDays)",
                    label: "最长陪伴",
                    icon: "hourglass"
                )
                StatCard(
                    value: priceString(stats.totalPurchasePrice),
                    label: "购入总价",
                    icon: "yensign.circle"
                )
            }

            if let avg = stats.averageEmotion {
                HStack(spacing: 12) {
                    StatCard(
                        value: String(format: "%.1f", avg),
                        label: "情感均值",
                        icon: "star.fill"
                    )
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }

            if !stats.categoryBreakdown.isEmpty {
                CategoryBreakdownView(items: stats.categoryBreakdown)
            }
        }
    }

    private func priceString(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "%.1fk", price / 1000)
        }
        if price == 0 {
            return "—"
        }
        return String(format: "%.0f", price)
    }
}

private struct StatCard: View {
    @Environment(\.appTheme) private var theme
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(theme.accent)
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(theme.secondary)
            }

            Text(value)
                .font(AppTypography.stat)
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

private struct CategoryBreakdownView: View {
    @Environment(\.appTheme) private var theme
    let items: [CategoryCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类分布")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)

            ForEach(items, id: \.category) { item in
                HStack(spacing: 12) {
                    Label(item.category.displayName, systemImage: item.category.iconName)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.primaryText)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { proxy in
                        let maxCount = items.first?.count ?? 1
                        let ratio = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.divider)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.accent)
                                .frame(width: proxy.size.width * ratio)
                        }
                    }
                    .frame(height: 6)

                    Text("\(item.count)")
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }
}

#Preview("累计") {
    let theme = AppTheme(mode: .light)
    let stats = FarewellStats(
        totalCount: 12,
        averageCompanionshipDays: 70.4,
        longestCompanionshipDays: 365,
        totalPurchasePrice: 1280,
        categoryBreakdown: [
            CategoryCount(category: .builtin(.clothing), count: 5),
            CategoryCount(category: .builtin(.books), count: 3),
            CategoryCount(category: .builtin(.electronics), count: 2),
            CategoryCount(category: .builtin(.other), count: 2),
        ],
        averageEmotion: 3.8
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
            averageEmotion: nil
        ))
        .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}
