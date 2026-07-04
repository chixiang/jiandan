import SwiftUI
import SwiftData

/// Namespace for hero transitions (card photo ↔ detail photo)
struct HeroNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var heroNamespace: Namespace.ID? {
        get { self[HeroNamespaceKey.self] }
        set { self[HeroNamespaceKey.self] = newValue }
    }
}

/// 列表排序方式
enum SortKey: String, CaseIterable {
    case farewellDate = "告别日期"
    case purchaseDate = "获得日期"
    case price = "价格"

    var localizedName: String {
        switch self {
        case .farewellDate: return String(localized: "告别日期")
        case .purchaseDate: return String(localized: "获得日期")
        case .price: return String(localized: "价格")
        }
    }

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
    @Environment(\.appTheme) private var theme
    @Namespace private var heroNamespace
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var selectedMethods: Set<String> = []
    @State private var selectedEmotions: Set<Int> = []
    @State private var isFilterExpanded = false
    @State private var sortKey: SortKey = .farewellDate
    @State private var sortAscending = false
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

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
                    searchText: searchText,
                    sortKey: sortKey,
                    sortAscending: sortAscending,
                    heroNamespace: heroNamespace,
                    onAddTapped: { showingAdd = true },
                    onClearFilter: {
                        selectedCategoryIDs = []
                        selectedMethods = []
                        selectedEmotions = []
                    }
                )
            }
            .background(theme.background)
            .navigationDestination(for: FarewellRecord.self) { record in
                FarewellDetailView(record: record)
                    .environment(\.heroNamespace, heroNamespace)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isSearching {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSearching = true
                                isSearchFocused = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .symbolEffect(.bounce, value: isSearching)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    if isSearching {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(theme.secondary)
                            TextField(String(localized: "搜索物品名称..."), text: $searchText)
                                .textFieldStyle(.plain)
                                .focused($isSearchFocused)
                            Button(String(localized: "取消")) {
                                searchText = ""
                                isSearching = false
                                isSearchFocused = false
                            }
                            .font(.subheadline)
                        }
                        .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            ForEach(SortKey.allCases, id: \.self) { key in
                                Button { sortKey = key } label: {
                                    HStack {
                                        Text(key.localizedName)
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
                            .font(.subheadline)
                            .accessibilityLabel("排序")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .symbolEffect(.bounce, value: showingAdd)
                    }
                    .accessibilityLabel("添加告别记录")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddFarewellView()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: sortKey)
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
    let searchText: String
    let sortKey: SortKey
    let sortAscending: Bool
    let heroNamespace: Namespace.ID
    let onAddTapped: () -> Void
    let onClearFilter: () -> Void

    init(
        selectedCategoryIDs: Set<String>,
        selectedMethods: Set<String>,
        selectedEmotions: Set<Int>,
        searchText: String,
        sortKey: SortKey,
        sortAscending: Bool,
        heroNamespace: Namespace.ID,
        onAddTapped: @escaping () -> Void,
        onClearFilter: @escaping () -> Void
    ) {
        self.selectedCategoryIDs = selectedCategoryIDs
        self.selectedMethods = selectedMethods
        self.selectedEmotions = selectedEmotions
        self.searchText = searchText
        self.sortKey = sortKey
        self.sortAscending = sortAscending
        self.heroNamespace = heroNamespace
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
            && (searchText.isEmpty || record.name.localizedStandardContains(searchText))
        }
    }

    private var isFiltering: Bool {
        !selectedCategoryIDs.isEmpty || !selectedMethods.isEmpty || !selectedEmotions.isEmpty || !searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if isFiltering {
                HStack {
                    Text(String.localizedStringWithFormat(
                        String(localized: "告别清单 (%lld)"), displayedRecords.count
                    ))
                    .appFont(.caption)
                    .foregroundStyle(theme.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            Group {
                if displayedRecords.isEmpty {
                    if isFiltering {
                        filteredEmptyView
                    } else {
                        DiaryEmptyView(onAddTapped: onAddTapped)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(displayedRecords.enumerated()), id: \.element.id) { index, record in
                                NavigationLink(value: record) {
                                    FarewellCardView(record: record)
                                }
                                .buttonStyle(.plain)
                                .environment(\.heroNamespace, heroNamespace)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.85)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private var filteredEmptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(theme.secondary)
            Text(!searchText.isEmpty ? String(localized: "未找到相关物品") : String(localized: "该分类下暂无告别记录"))
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
