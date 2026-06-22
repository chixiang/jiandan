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
            .navigationTitle("减单")
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

#Preview {
    DiaryView()
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}
