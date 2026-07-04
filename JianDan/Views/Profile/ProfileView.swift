import SwiftUI
import SwiftData

/// 「我的」Tab：统计数据 + 设置
struct ProfileView: View {
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    @State private var showingSettings = false

    private var stats: FarewellStats {
        StatsCalculator.compute(from: records)
    }

    var body: some View {
        NavigationStack {
            Group {
                if stats.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            StatsView(stats: stats)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .appFont(.body)
                .foregroundStyle(theme.secondary)
            Text("在「告别清单」Tab 记下第一件物品，\n统计就会出现在这里")
                .appFont(.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
