import SwiftUI
import SwiftData

/// 「我的」Tab：统计数据 + 设置
///
/// 支持按月切片查看统计：
/// - 顶部 picker 切换"累计 / 某月"
/// - 切换月份时统计重算，分类分布与陪伴/总价都按月
struct ProfileView: View {
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    /// 当前选中的 scope：`.allTime` 或 `.month(ym)`
    @State private var scope: StatsScope = .allTime

    /// 缓存的"有记录的月份"列表（按时间倒序）
    private var availableMonths: [YearMonth] {
        StatsCalculator.monthsWithRecords(in: records)
    }

    /// 当前 scope 下的统计数据
    private var stats: FarewellStats {
        StatsCalculator.compute(from: records, scope: scope)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 月份选择器（仅在有数据时显示）
                    if !availableMonths.isEmpty {
                        MonthScopePicker(
                            scope: $scope,
                            availableMonths: availableMonths
                        )
                    }

                    // 统计区
                    if stats.isEmpty {
                        emptyStateView
                    } else {
                        StatsView(stats: stats)
                    }

                    // 设置区（始终显示）
                    SettingsView()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.background)
            .navigationTitle("我的")
        }
        .onAppear {
            // 首次进入：默认累计
            if case .month = scope {
                // 保持上次选择
            } else if scope == .allTime {
                // 默认
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text(emptyTitle)
                .font(AppTypography.body)
                .foregroundStyle(theme.secondary)
            Text(emptySubtitle)
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.bottom, 12)
    }

    private var emptyTitle: String {
        switch scope {
        case .allTime: return "还没有告别记录"
        case .month(let ym): return "\(ym.year) 年 \(ym.month) 月，尚无告别"
        }
    }

    private var emptySubtitle: String {
        switch scope {
        case .allTime:
            return "在「减单」Tab 记下第一件物品，\n统计就会出现在这里"
        case .month:
            return "换个月份看看，或\n回到「减单」Tab 记下当月的告别"
        }
    }
}

/// 月份范围选择器
///
/// 布局：
/// - 累计 tab + 各月 tab（按时间倒序）
/// - 横向滚动避免挤压
private struct MonthScopePicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var scope: StatsScope
    let availableMonths: [YearMonth]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 「累计」tab
                ScopeChip(
                    label: "累计",
                    isSelected: scope == .allTime
                ) {
                    scope = .allTime
                }

                // 各月 tab
                ForEach(availableMonths, id: \.self) { ym in
                    ScopeChip(
                        label: "\(ym.year) 年 \(ym.month) 月",
                        isSelected: scope == .month(ym)
                    ) {
                        scope = .month(ym)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// 单个 chip
private struct ScopeChip: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(isSelected ? Color.white : theme.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.accent : theme.cardBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.divider, lineWidth: isSelected ? 0 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environment(\.appTheme, AppTheme(mode: .light))
        .environment(ThemeManager())
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}

#Preview("深色主题") {
    ProfileView()
        .environment(\.appTheme, AppTheme(mode: .dark))
        .environment(ThemeManager())
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}