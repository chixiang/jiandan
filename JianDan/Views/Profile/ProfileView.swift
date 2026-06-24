import SwiftUI
import SwiftData

/// 「我的」Tab：统计数据 + 设置
///
/// 月份选择放在导航栏 toolbar 中，以 Menu 形式展开。
/// 默认「累计」，可选任意有数据的月份。
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

    /// 当前选择在 Menu 中的显示文字
    private var scopeLabel: String {
        switch scope {
        case .allTime: return "累计"
        case .month(let ym): return "\(ym.year) 年 \(ym.month) 月"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
            .toolbar {
                // 月份选择菜单（仅在有数据时显示）
                if !availableMonths.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("统计范围", selection: $scope) {
                                Text("累计").tag(StatsScope.allTime)
                                ForEach(availableMonths, id: \.self) { ym in
                                    Text("\(ym.year) 年 \(ym.month) 月")
                                        .tag(StatsScope.month(ym))
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(scopeLabel)
                                    .font(.subheadline)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(theme.accent)
                        }
                    }
                }
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
            return "在「减单」Tab 记下第一件物品，\\n统计就会出现在这里"
        case .month:
            return "换个月份看看，或\\n回到「减单」Tab 记下当月的告别"
        }
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