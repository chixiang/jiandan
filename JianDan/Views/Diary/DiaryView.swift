import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    DiaryEmptyView(onAddTapped: { showingAdd = true })
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
            .background(Color(.systemBackground))
            .navigationTitle("告别")
            .navigationDestination(for: FarewellRecord.self) { record in
                // Task 9 会替换为 FarewellDetailView
                Text(record.name)
                    .navigationTitle(record.name)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加告别")
                }
            }
            .sheet(isPresented: $showingAdd) {
                // Task 7 会替换为 AddFarewellView
                AddFarewellPlaceholder()
            }
        }
    }
}

/// 临时添加告别占位（Task 7 替换）
struct AddFarewellPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("新建告别表单（待 Task 7 实现）")
                .foregroundStyle(.secondary)
                .navigationTitle("告别")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    DiaryView()
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}
