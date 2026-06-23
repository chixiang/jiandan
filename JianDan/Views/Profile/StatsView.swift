import SwiftUI

/// 告别统计卡片网格
///
/// 展示告别数 / 陪伴累计 / 本月数 / 总价等关键指标。
/// 数据由 `StatsCalculator.compute(from:)` 提供；本 View 只负责渲染。
struct StatsView: View {
    @Environment(\.appTheme) private var theme
    let stats: FarewellStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("统计")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .tracking(2)
                .padding(.horizontal, 4)

            // 第一行：告别总数 / 本月数
            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.totalCount)",
                    label: "总告别数",
                    icon: "leaf.fill"
                )
                StatCard(
                    value: "\(stats.thisMonthCount)",
                    label: "本月",
                    icon: "calendar"
                )
            }

            // 第二行：陪伴总天数 / 最久
            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.totalCompanionshipDays)",
                    label: "陪伴总天数",
                    icon: "heart.fill"
                )
                StatCard(
                    value: "\(stats.longestCompanionshipDays)",
                    label: "最长陪伴",
                    icon: "hourglass"
                )
            }

            // 第三行：购入总价 / 情感均值（只在有数据时显示）
            if stats.totalPurchasePrice > 0 || stats.averageEmotion != nil {
                HStack(spacing: 12) {
                    if stats.totalPurchasePrice > 0 {
                        StatCard(
                            value: priceString(stats.totalPurchasePrice),
                            label: "购入总价",
                            icon: "yensign.circle"
                        )
                    }
                    if let avg = stats.averageEmotion {
                        StatCard(
                            value: String(format: "%.1f", avg),
                            label: "情感均值",
                            icon: "star.fill"
                        )
                    } else if stats.totalPurchasePrice > 0 {
                        // 占位空白让布局平衡
                        StatCard(value: "—", label: "情感均值", icon: "star")
                    }
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

#Preview {
    let theme = AppTheme(mode: .light)
    let stats = FarewellStats(
        totalCount: 12,
        totalCompanionshipDays: 845,
        longestCompanionshipDays: 365,
        thisMonthCount: 3,
        totalPurchasePrice: 1280,
        categoryBreakdown: [
            CategoryCount(category: .clothing, count: 5),
            CategoryCount(category: .books, count: 3),
            CategoryCount(category: .electronics, count: 2),
            CategoryCount(category: .other, count: 2),
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
            totalCompanionshipDays: 0,
            longestCompanionshipDays: 0,
            thisMonthCount: 0,
            totalPurchasePrice: 0,
            categoryBreakdown: [],
            averageEmotion: nil
        ))
        .padding()
    }
    .background(theme.background)
    .environment(\.appTheme, theme)
}