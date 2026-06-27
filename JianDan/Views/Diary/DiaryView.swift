import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedStorageIDs: Set<String> = []
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterBar(selectedStorageIDs: $selectedStorageIDs)
                DiaryListView(
                    selectedStorageIDs: selectedStorageIDs,
                    onAddTapped: { showingAdd = true },
                    onClearFilter: { selectedStorageIDs = [] }
                )
            }
            .background(Color(.systemBackground))
            .navigationDestination(for: FarewellRecord.self) { record in
                FarewellDetailView(record: record)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加减单记录")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddFarewellView()
            }
        }
    }

}

// MARK: - 筛选列表

private struct DiaryListView: View {
    @Environment(\.appTheme) private var theme
    @Query private var records: [FarewellRecord]
    let selectedStorageIDs: Set<String>
    let onAddTapped: () -> Void
    let onClearFilter: () -> Void

    init(
        selectedStorageIDs: Set<String>,
        onAddTapped: @escaping () -> Void,
        onClearFilter: @escaping () -> Void
    ) {
        self.selectedStorageIDs = selectedStorageIDs
        self.onAddTapped = onAddTapped
        self.onClearFilter = onClearFilter
        if selectedStorageIDs.isEmpty {
            _records = Query(sort: [SortDescriptor(\.farewellDate, order: .reverse)])
        } else {
            let ids = selectedStorageIDs
            _records = Query(
                filter: #Predicate { ids.contains($0.categoryRaw) },
                sort: [SortDescriptor(\.farewellDate, order: .reverse)]
            )
        }
    }

    var body: some View {
        Group {
            if records.isEmpty {
                if selectedStorageIDs.isEmpty {
                    DiaryEmptyView(onAddTapped: onAddTapped)
                } else {
                    filteredEmptyView
                }
            } else {
                List {
                    ForEach(records) { record in
                        NavigationLink(value: record) {
                            FarewellCardView(record: record)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(title)
    }

    private var title: String {
        if selectedStorageIDs.isEmpty { return "减单" }
        return "减单 (\(records.count))"
    }

    private var filteredEmptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(theme.secondary)
            Text("该分类下暂无告别记录")
                .foregroundStyle(theme.secondary)
            Button("清除筛选", action: onClearFilter)
                .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DiaryView()
        .modelContainer(for: [FarewellRecord.self, UserCategory.self], inMemory: true)
}
