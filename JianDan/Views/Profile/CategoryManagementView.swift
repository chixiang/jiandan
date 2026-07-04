import SwiftUI
import SwiftData

/// 分类管理页
///
/// 列出：
/// - 12 个内置分类（只读，不能删）
/// - 用户自定义分类（可点击删除，长按也有同样效果）
/// 顶部「+ 新分类」按钮弹出 NewCategorySheet
struct CategoryManagementView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]

    @State private var showingNewCategorySheet = false
    @State private var deleteTarget: UserCategory? = nil
    @State private var deleteConfirmTarget: UserCategory? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("内置分类") {
                    ForEach(Category.allCases) { cat in
                        CategoryManagementRow(
                            name: cat.localizedName,
                            iconName: cat.icon,
                            canDelete: false,
                            onDelete: nil
                        )
                    }
                }

                Section {
                    if customCategories.isEmpty {
                        Text("暂无自定义分类")
                            .appFont(.body)
                            .foregroundStyle(theme.secondary)
                    } else {
                        ForEach(customCategories, id: \.id) { cat in
                            CategoryManagementRow(
                                name: cat.name,
                                iconName: cat.iconName,
                                canDelete: true,
                                onDelete: { deleteTarget = cat }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = cat
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("自定义分类")
                } footer: {
                    Text("删除自定义分类时，引用它的记录会自动归入「其他」。")
                        .appFont(.caption)
                }
            }
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingNewCategorySheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCategorySheet) {
                NewCategorySheet()
            }
            .alert(
                "删除自定义分类？",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                presenting: deleteTarget
            ) { cat in
                Button("删除", role: .destructive) {
                    performDelete(cat)
                }
                Button("取消", role: .cancel) {}
            } message: { cat in
                let count = referencingCount(for: cat.id.uuidString)
                if count > 0 {
                    Text("「\(cat.name)」关联了 \(count) 条记录，删除后将归入「其他」。")
                } else {
                    Text("「\(cat.name)」将被删除。")
                }
            }
        }
    }

    private func referencingCount(for categoryID: String) -> Int {
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.categoryRaw == categoryID }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    private func performDelete(_ cat: UserCategory) {
        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: AnyCategory.storageIDForDelete(userCategory: cat),
            toCategoryID: Category.other.rawValue,
            in: modelContext
        )
        modelContext.delete(cat)
        try? modelContext.save()
        deleteTarget = nil
    }
}

/// 单行：图标 + 名称 + 删除按钮
private struct CategoryManagementRow: View {
    @Environment(\.appTheme) private var theme
    let name: String
    let iconName: String
    let canDelete: Bool
    let onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(theme.primaryText)
            Text(name)
                .appFont(.body)
            Spacer()
            if !canDelete {
                Text("内置")
                    .appFont(.caption)
                    .foregroundStyle(theme.secondary)
            }
        }
    }
}

#Preview {
    CategoryManagementView()
        .modelContainer(for: [UserCategory.self, FarewellRecord.self], inMemory: true)
}