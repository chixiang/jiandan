import SwiftUI
import SwiftData

/// 列表排序方式
enum SortKey: String, CaseIterable {
    case farewellDate = "减单日期"
    case purchaseDate = "购入日期"
    case price = "价格"

    func descriptor(ascending: Bool) -> SortDescriptor<FarewellRecord> {
        let order: SortOrder = ascending ? .forward : .reverse
        switch self {
        case .farewellDate: return SortDescriptor(\.farewellDate, order: order)
        case .purchaseDate: return SortDescriptor(\.purchaseDate, order: order)
        case .price:        return SortDescriptor(\.purchasePrice, order: order)
        }
    }
}

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var selectedMethods: Set<String> = []
    @State private var selectedEmotions: Set<Int> = []
    @State private var isFilterExpanded = false
    @State private var sortKey: SortKey = .farewellDate
    @State private var sortAscending = false
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterBar(
                    selectedCategoryIDs: $selectedCategoryIDs,
                    selectedMethods: $selectedMethods,
                    selectedEmotions: $selectedEmotions,
                    isExpanded: $isFilterExpanded
                )
                DiaryListView(
                    selectedCategoryIDs: selectedCategoryIDs,
                    selectedMethods: selectedMethods,
                    selectedEmotions: selectedEmotions,
                    sortKey: sortKey,
                    sortAscending: sortAscending,
                    onAddTapped: { showingAdd = true },
                    onClearFilter: {
                        selectedCategoryIDs = []
                        selectedMethods = []
                        selectedEmotions = []
                    }
                )
            }
            .background(Color(.systemBackground))
            .navigationDestination(for: FarewellRecord.self) { record in
                FarewellDetailView(record: record)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            ForEach(SortKey.allCases, id: \.self) { key in
                                Button { sortKey = key } label: {
                                    HStack {
                                        Text(key.rawValue)
                                        if key == sortKey {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        Section {
                            Button { sortAscending = false } label: {
                                HStack {
                                    if !sortAscending { Image(systemName: "checkmark") }
                                    Text("倒序")
                                }
                            }
                            Button { sortAscending = true } label: {
                                HStack {
                                    if sortAscending { Image(systemName: "checkmark") }
                                    Text("正序")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityLabel("排序")
                    }
                }
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
    let selectedCategoryIDs: Set<String>
    let selectedMethods: Set<String>
    let selectedEmotions: Set<Int>
    let sortKey: SortKey
    let sortAscending: Bool
    let onAddTapped: () -> Void
    let onClearFilter: () -> Void

    init(
        selectedCategoryIDs: Set<String>,
        selectedMethods: Set<String>,
        selectedEmotions: Set<Int>,
        sortKey: SortKey,
        sortAscending: Bool,
        onAddTapped: @escaping () -> Void,
        onClearFilter: @escaping () -> Void
    ) {
        self.selectedCategoryIDs = selectedCategoryIDs
        self.selectedMethods = selectedMethods
        self.selectedEmotions = selectedEmotions
        self.sortKey = sortKey
        self.sortAscending = sortAscending
        self.onAddTapped = onAddTapped
        self.onClearFilter = onClearFilter
        let sort = [sortKey.descriptor(ascending: sortAscending)]
        _records = Query(sort: sort)
    }

    private var displayedRecords: [FarewellRecord] {
        records.filter { record in
            (selectedCategoryIDs.isEmpty || selectedCategoryIDs.contains(record.categoryRaw))
            && (selectedMethods.isEmpty || selectedMethods.contains(record.methodRaw))
            && (selectedEmotions.isEmpty || selectedEmotions.contains(record.emotionValue ?? -1))
        }
    }

    private var isFiltering: Bool {
        !selectedCategoryIDs.isEmpty || !selectedMethods.isEmpty || !selectedEmotions.isEmpty
    }

    var body: some View {
        Group {
            if displayedRecords.isEmpty {
                if isFiltering {
                    filteredEmptyView
                } else {
                    DiaryEmptyView(onAddTapped: onAddTapped)
                }
            } else {
                List {
                    ForEach(displayedRecords) { record in
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
        isFiltering ? "减单 (\(displayedRecords.count))" : "减单"
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
