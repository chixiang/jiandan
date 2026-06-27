import SwiftUI
import SwiftData

/// 减单详情页
struct FarewellDetailView: View {
    @Bindable var record: FarewellRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm = false
    @State private var showingEdit = false
    @State private var deleteCustomCategoryAlert: UserCategory? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 照片轮播
                PhotoCarouselView(filenames: record.photoFilenames)

                // 名称 + 日期
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.name)
                        .font(.title)
                        .fontWeight(.regular)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(record.farewellDate, format: .dateTime.year().month().day())
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        if let days = record.companionshipDays {
                            Text("陪伴了 \(days) 天")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Divider()

                // 分类与去向
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(
                        icon: record.category.iconName,
                        label: "分类",
                        value: record.category.displayName
                    )
                    DetailRow(
                        icon: record.method.icon,
                        label: "去向",
                        value: record.method.rawValue
                    )
                    if let detail = record.recipientDetail, !detail.isEmpty {
                        DetailRow(
                            icon: "person",
                            label: "收件 / 详情",
                            value: detail
                        )
                    }
                }

                // 情感值
                if let emotion = record.emotionValue {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当时心情")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(1...3, id: \.self) { i in
                                Circle()
                                    .fill(i <= emotion ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 10, height: 10)
                            }
                            Text(emotionLabel(emotion))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                // 购入信息
                if record.purchaseDate != nil || record.purchasePrice != nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("购入")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let date = record.purchaseDate {
                            Text("购于 \(date.formatted(.dateTime.year().month().day()))")
                                .font(.body)
                        }
                        if let price = record.purchasePrice {
                            Text("价格 ¥\(price, specifier: "%.0f")")
                                .font(.body)
                        }
                    }
                }

                // 减单一言
                if let letter = record.farewellLetter, !letter.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("减单一言")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(letter)
                            .font(.body)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                // 元数据
                VStack(alignment: .leading, spacing: 4) {
                    Text("记录于 \(record.createdAt.formatted(.dateTime.year().month().day().hour().minute()))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if record.updatedAt != record.createdAt {
                        Text("更新于 \(record.updatedAt.formatted(.dateTime.year().month().day().hour().minute()))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "确认删除这条减单？",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                deleteRecord()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("「\(record.name)」将被永久删除，相关照片也会一并清理。")
        }
        .sheet(isPresented: $showingEdit) {
            EditFarewellView(record: record)
        }
        .alert(
            "删除自定义分类？",
            isPresented: Binding(
                get: { deleteCustomCategoryAlert != nil },
                set: { if !$0 { deleteCustomCategoryAlert = nil } }
            ),
            presenting: deleteCustomCategoryAlert
        ) { cat in
            Button("删除", role: .destructive) {
                performDeleteCustomCategory(cat)
            }
            Button("取消", role: .cancel) {}
        } message: { cat in
            let count = referencingRecordCount(for: AnyCategory.storageIDForDelete(userCategory: cat))
            if count > 0 {
                Text("「\(cat.name)」关联了 \(count) 条记录，删除后将归入「其他」。")
            } else {
                Text("「\(cat.name)」将被删除。")
            }
        }
    }

    private func emotionLabel(_ value: Int) -> String {
        switch value {
        case 1: return "平静"
        case 2: return "复杂"
        case 3: return "不舍"
        default: return ""
        }
    }

    private func deleteRecord() {
        do {
            try RecordDeleter.delete(record, in: modelContext)
            dismiss()
        } catch {
            print("Delete failed: \(error)")
        }
    }

    private func referencingRecordCount(for categoryID: String) -> Int {
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.categoryRaw == categoryID }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    private func performDeleteCustomCategory(_ cat: UserCategory) {
        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: AnyCategory.storageIDForDelete(userCategory: cat),
            toCategoryID: Category.other.rawValue,
            in: modelContext
        )
        modelContext.delete(cat)
        try? modelContext.save()
    }
}

/// 详情行（图标 + 标签 + 值）
private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 编辑页

/// 编辑页（Phase 1 简化版：仅编辑文本字段，不支持修改照片）
struct EditFarewellView: View {
    @Bindable var record: FarewellRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var deleteCustomCategoryAlert: UserCategory? = nil
    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("名称", text: $record.name)
                        .onChange(of: record.name) { _, _ in
                            EditFarewellSaver.truncateName(record)
                        }
                }

                Section("减单日期") {
                    DatePicker("日期", selection: $record.farewellDate, in: ...Date.now, displayedComponents: .date)
                }

                Section("分类") {
                    CategoryPickerSection(
                        selection: Binding(
                            get: { record.category },
                            set: { newValue in record.categoryID = newValue.storageID }
                        ),
                        onRequestDelete: { cat in
                            if case .custom(let name, _) = cat {
                                let found = customCategories.first(where: { $0.name == name })
                                deleteCustomCategoryAlert = found
                            }
                        }
                    )
                }

                Section("去向") {
                    MethodPickerSection(selection: Binding(
                        get: { record.method },
                        set: { record.method = $0 }
                    ))
                    if record.method != .discard && record.method != .other {
                        TextField("送给谁 / 去向详情", text: Binding(
                            get: { record.recipientDetail ?? "" },
                            set: { record.recipientDetail = $0.isEmpty ? nil : $0 }
                        ))
                        .onChange(of: record.recipientDetail ?? "") { _, _ in
                            EditFarewellSaver.truncateRecipientDetail(record)
                        }
                    }
                }

                Section("更多") {
                    Toggle("记录购入日期", isOn: Binding(
                        get: { record.purchaseDate != nil },
                        set: { newValue in
                            if newValue {
                                record.purchaseDate = record.farewellDate.addingTimeInterval(-365 * 86400)
                            } else {
                                record.purchaseDate = nil
                            }
                        }
                    ))

                    if record.purchaseDate != nil {
                        DatePicker("购入日期", selection: Binding(
                            get: { record.purchaseDate ?? Date.now.addingTimeInterval(-365 * 86400) },
                            set: { record.purchaseDate = $0 }
                        ), in: ...record.farewellDate, displayedComponents: .date)
                    }

                    TextField("购入价格（选填）", text: Binding(
                        get: {
                            if let price = record.purchasePrice, price > 0 {
                                return String(format: "%.0f", price)
                            }
                            return ""
                        },
                        set: { newValue in
                            if let price = Double(newValue), price > 0 {
                                record.purchasePrice = price
                            } else {
                                record.purchasePrice = nil
                            }
                        }
                    ))
                    .keyboardType(.decimalPad)

                    EmotionStarsView(value: Binding(
                        get: { record.emotionValue },
                        set: { record.emotionValue = $0 }
                    ))
                }

                Section("减单一言") {
                    TextField("写一段话给它", text: Binding(
                        get: { record.farewellLetter ?? "" },
                        set: { record.farewellLetter = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...10)
                    .onChange(of: record.farewellLetter ?? "") { _, _ in
                        EditFarewellSaver.truncateFarewellLetter(record)
                    }
                }
            }
            .navigationTitle("编辑减单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert(
                "删除自定义分类？",
                isPresented: Binding(
                    get: { deleteCustomCategoryAlert != nil },
                    set: { if !$0 { deleteCustomCategoryAlert = nil } }
                ),
                presenting: deleteCustomCategoryAlert
            ) { cat in
                Button("删除", role: .destructive) {
                    performDeleteCustomCategory(cat)
                }
                Button("取消", role: .cancel) {}
            } message: { cat in
                let count = referencingRecordCount(for: AnyCategory.storageIDForDelete(userCategory: cat))
                if count > 0 {
                    Text("「\(cat.name)」关联了 \(count) 条记录，删除后将归入「其他」。")
                } else {
                    Text("「\(cat.name)」将被删除。")
                }
            }
        }
    }

    private func referencingRecordCount(for categoryID: String) -> Int {
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.categoryRaw == categoryID }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    private func performDeleteCustomCategory(_ cat: UserCategory) {
        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: AnyCategory.storageIDForDelete(userCategory: cat),
            toCategoryID: Category.other.rawValue,
            in: modelContext
        )
        modelContext.delete(cat)
        try? modelContext.save()
    }

    private func save() {
        do {
            try EditFarewellSaver.save(record, in: modelContext)
            dismiss()
        } catch {
            print("Edit save failed: \(error)")
        }
    }
}