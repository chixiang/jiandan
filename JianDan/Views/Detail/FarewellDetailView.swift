import SwiftUI
import SwiftData

/// 告别清单详情页
struct FarewellDetailView: View {
    @Bindable var record: FarewellRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(CurrencyManager.self) private var currencyManager

    @State private var showingDeleteConfirm = false
    @State private var showingEdit = false
    @State private var deleteCustomCategoryAlert: UserCategory? = nil
    @State private var showDetailShare = false

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
                        value: record.method.localizedName
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
                                    .fill(i <= emotion ? theme.accent : Color.secondary.opacity(0.3))
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
                        Text("获得")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let date = record.purchaseDate {
                            Text("获得于 \(date.formatted(.dateTime.year().month().day()))")
                                .font(.body)
                        }
                        if let price = record.purchasePrice {
                            HStack(spacing: 4) {
                                Image(systemName: currencyManager.currency.icon)
                                    .foregroundStyle(.secondary)
                                Text(price, format: .number.precision(.fractionLength(2)))
                            }
                            .font(.body)
                        }
                    }
                }

                // 告别留言
                if let letter = record.farewellLetter, !letter.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("告别留言")
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
                    Button {
                        showDetailShare = true
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
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
            "确认删除这条告别记录？",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                deleteRecord()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(String.localizedStringWithFormat(
                String(localized: "「%@」将被永久删除，相关照片也会一并清理。"),
                record.name
            ))
        }
        .sheet(isPresented: $showingEdit) {
            EditFarewellView(record: record)
        }
        .fullScreenCover(isPresented: $showDetailShare) {
            SharePreviewView(
                record: record,
                onClose: { showDetailShare = false }
            )
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
                Text(String.localizedStringWithFormat(
                    String(localized: "「%@」关联了 %lld 条记录，删除后将归入「其他」。"),
                    cat.name, count
                ))
            } else {
                Text(String.localizedStringWithFormat(
                    String(localized: "「%@」将被删除。"),
                    cat.name
                ))
            }
        }
    }

    private func emotionLabel(_ value: Int) -> String {
        switch value {
        case 1: return String(localized: "平静")
        case 2: return String(localized: "复杂")
        case 3: return String(localized: "不舍")
        default: return ""
        }
    }

    private func deleteRecord() {
        do {
            try RecordDeleter.delete(record, in: modelContext)
            dismiss()
        } catch {
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
    let label: LocalizedStringKey
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

/// 编辑页
struct EditFarewellView: View {
    @Bindable var record: FarewellRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(CurrencyManager.self) private var currencyManager

    @State private var photos: [PhotoItem] = []
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

                Section {
                    PhotoPickerSection(items: $photos)
                }

                Section("告别日期") {
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
                    Toggle("记录获得日期", isOn: Binding(
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
                        DatePicker("获得日期", selection: Binding(
                            get: { record.purchaseDate ?? Date.now.addingTimeInterval(-365 * 86400) },
                            set: { record.purchaseDate = $0 }
                        ), in: ...record.farewellDate, displayedComponents: .date)
                    }

                    PriceInputView(
                        price: Binding(
                            get: { record.purchasePrice },
                            set: { record.purchasePrice = $0 }
                        ),
                        symbol: currencyManager.currency.symbol
                    )

                    EmotionStarsView(value: Binding(
                        get: { record.emotionValue },
                        set: { record.emotionValue = $0 }
                    ))
                }

                Section("告别留言") {
                    TextField("写一段话给它（选填）", text: Binding(
                        get: { record.farewellLetter ?? "" },
                        set: { record.farewellLetter = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...10)
                    .onChange(of: record.farewellLetter ?? "") { _, _ in
                        EditFarewellSaver.truncateFarewellLetter(record)
                    }
                }
            }
            .navigationTitle("编辑告别")
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
                    Text(String.localizedStringWithFormat(
                        String(localized: "「%@」关联了 %lld 条记录，删除后将归入「其他」。"),
                        cat.name, count
                    ))
                } else {
                    Text(String.localizedStringWithFormat(
                        String(localized: "「%@」将被删除。"),
                        cat.name
                    ))
                }
            }
        }
        .onAppear(perform: loadExistingPhotos)
    }

    private func loadExistingPhotos() {
        for filename in record.photoFilenames {
            if let data = ImageStore.load(filename: filename) {
                photos.append(PhotoItem(data: data, existingFilename: filename))
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
        // 记录当前已有的照片文件名
        let oldFilenames = Set(record.photoFilenames)
        let keptFilenames = photos.compactMap(\.existingFilename)
        let removedFilenames = Array(oldFilenames.subtracting(Set(keptFilenames)))

        // 删除已移除的照片文件
        if !removedFilenames.isEmpty {
            try? ImageStore.delete(filenames: removedFilenames)
        }

        // 保存新增的照片
        var newFilenames: [String] = []
        for photo in photos where photo.existingFilename == nil {
            if let filename = try? ImageStore.save(photo.data) {
                newFilenames.append(filename)
            }
        }

        // 更新记录的图片文件名列表（保持 photos 数组的顺序）
        record.photoFilenames = keptFilenames + newFilenames

        if record.photoFilenames.isEmpty {
            if let image = FarewellImageGenerator.generatePlaceholderImage(),
               let data = image.jpegData(compressionQuality: 0.85) {
                if let filename = try? ImageStore.save(data) {
                    record.photoFilenames = [filename]
                }
            }
        }

        do {
            try EditFarewellSaver.save(record, in: modelContext)
            dismiss()
        } catch {
        }
    }
}