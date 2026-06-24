import SwiftUI

/// 告别统计卡片网格
///
/// 展示告别数 / 陪伴累计 / 总价等关键指标。
/// 数据由 `StatsCalculator.compute(from:scope:)` 提供；本 View 只负责渲染。
///
/// 当 `stats.monthLabel` 非 nil 时（即按月切片），顶部显示副标题。
struct StatsView: View {
    @Environment(\.appTheme) private var theme
    let stats: FarewellStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("统计")
                    .font(AppTypography.caption)
                    .foregroundStyle(theme.secondary)
                    .tracking(2)

                if let monthLabel = stats.monthLabel {
                    Text(monthLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.secondary)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 4)

            // 第一行：告别数 / 陪伴天数
            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.totalCount)",
                    label: "告别数",
                    icon: "leaf.fill"
                )
                StatCard(
                    value: "\(stats.totalCompanionshipDays)",
                    label: "陪伴天数",
                    icon: "heart.fill"
                )
            }

            // 第二行：最长陪伴 / 总价
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

            // 第三行：情感均值（仅在有数据时显示）
            if let avg = stats.averageEmotion {
                HStack(spacing: 12) {
                    StatCard(
                        value: String(format: "%.1f", avg),
                        label: "情感均值",
                        icon: "star.fill"
                    )
                    // 占位让布局保持 2 列
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }

            // 分类分布
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

/// 单个统计卡片
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

/// 分类分布
private struct CategoryBreakdownView: View {
    @Environment(\.appTheme) private var theme
    let items: [CategoryCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类分布")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)

            // 横向柱状
            ForEach(items, id: \.category) { item in
                HStack(spacing: 12) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.primaryText)
                        .frame(width: 80, alignment: .leading)

                    // 进度条（相对于分类中最多的那个）
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
        totalCompanionshipDays: 845,
        longestCompanionshipDays: 365,
        totalPurchasePrice: 1280,
        categoryBreakdown: [
            CategoryCount(category: .clothing, count: 5),
            CategoryCount(category: .books, count: 3),
            CategoryCount(category: .electronics, count: 2),
            CategoryCount(category: .other, count: 2),
        ],
        averageEmotion: 3.8,
        monthLabel: nil
    )
    return ScrollView {
        StatsView(stats: stats)
            .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}

#Preview("按月") {
    let theme = AppTheme(mode: .light)
    let stats = FarewellStats(
        totalCount: 3,
        totalCompanionshipDays: 120,
        longestCompanionshipDays: 90,
        totalPurchasePrice: 480,
        categoryBreakdown: [
            CategoryCount(category: .clothing, count: 2),
            CategoryCount(category: .books, count: 1),
        ],
        averageEmotion: 4.0,
        monthLabel: "2026 年 6 月"
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
            totalCompanionshipDays: 0,
            longestCompanionshipDays: 0,
            totalPurchasePrice: 0,
            categoryBreakdown: [],
            averageEmotion: nil,
            monthLabel: nil
        ))
        .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}

#Preview("空月份") {
    let theme = AppTheme(mode: .light)
    return ScrollView {
        StatsView(stats: FarewellStats(
            totalCount: 0,
            totalCompanionshipDays: 0,
            longestCompanionshipDays: 0,
            totalPurchasePrice: 0,
            categoryBreakdown: [],
            averageEmotion: nil,
            monthLabel: "2025 年 3 月"
        ))
        .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}