import SwiftUI
import SwiftData

/// 新建减单表单
struct AddFarewellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(CurrencyManager.self) private var currencyManager

    @State private var name: String = ""
    @State private var category: AnyCategory = .builtin(.clothing)
    @State private var method: FarewellMethod = .donate
    @State private var farewellDate: Date = .now
    @State private var purchaseDate: Date? = nil
    @State private var purchasePriceText: String = ""
    @State private var recipientDetail: String = ""
    @State private var farewellLetter: String = ""
    @State private var emotionValue: Int? = nil
    @State private var photos: [PhotoItem] = []

    @State private var showPurchaseDate: Bool = false

    private var canSave: Bool {
        AddFarewellValidator.canSave(name: name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoPickerSection(items: $photos)
                }

                Section("物品信息") {
                    TextField("名称（如：一件蓝色羊毛大衣）", text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > FarewellRecord.nameMaxLength {
                                name = String(newValue.prefix(FarewellRecord.nameMaxLength))
                            }
                        }

                    DatePicker("减单日期", selection: $farewellDate, in: ...Date.now, displayedComponents: .date)
                }

                Section("分类与去向") {
                    CategoryPickerSection(selection: $category)
                    MethodPickerSection(selection: $method)

                    if method != .discard && method != .other {
                        TextField("送给谁 / 去向详情", text: $recipientDetail)
                            .onChange(of: recipientDetail) { _, newValue in
                                if newValue.count > FarewellRecord.recipientDetailMaxLength {
                                    recipientDetail = String(newValue.prefix(FarewellRecord.recipientDetailMaxLength))
                                }
                            }
                    }
                }

                Section("更多") {
                    Toggle("记录购入日期", isOn: $showPurchaseDate)

                    if showPurchaseDate {
                        DatePicker("购入日期", selection: Binding(
                            get: { purchaseDate ?? Date.now.addingTimeInterval(-365 * 86400) },
                            set: { purchaseDate = $0 }
                        ), in: ...farewellDate, displayedComponents: .date)
                    }

                    HStack(spacing: 6) {
                        Text(currencyManager.currency.symbol)
                            .foregroundStyle(theme.secondary)
                        TextField("购入价格（选填）", text: $purchasePriceText)
                            .keyboardType(.decimalPad)
                    }

                    EmotionStarsView(value: $emotionValue)
                }

                Section {
                    TextField("写一段话给它（选填）", text: $farewellLetter, axis: .vertical)
                        .lineLimit(3...10)
                        .onChange(of: farewellLetter) { _, newValue in
                            if newValue.count > FarewellRecord.farewellLetterMaxLength {
                                farewellLetter = String(newValue.prefix(FarewellRecord.farewellLetterMaxLength))
                            }
                        }
                } header: {
                    Text("减单一言")
                } footer: {
                    HStack {
                        Spacer()
                        Text("\(farewellLetter.count) / \(FarewellRecord.farewellLetterMaxLength)")
                            .font(.caption)
                            .foregroundStyle(farewellLetter.count > FarewellRecord.farewellLetterMaxLength * 4 / 5 ? .orange : .secondary)
                    }
                }
            }
            .navigationTitle("新建减单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 把 Data 转 filenames（先存图，再构造 record）
        var savedFilenames: [String] = []
        for photo in photos {
            do {
                let filename = try ImageStore.save(photo.data)
                savedFilenames.append(filename)
            } catch {
                // Phase 1 暂不实现完整错误提示；本张图片不入库，继续保存其余
                print("ImageStore save failed: \(error)")
            }
        }

        let price = Double(purchasePriceText)
        let record = FarewellRecord(
            name: trimmedName,
            category: category,
            farewellDate: farewellDate,
            method: method,
            photoFilenames: savedFilenames
        )
        record.purchaseDate = purchaseDate
        record.purchasePrice = (price ?? 0) > 0 ? price : nil
        record.emotionValue = emotionValue
        record.recipientDetail = recipientDetail.isEmpty ? nil : recipientDetail
        record.farewellLetter = farewellLetter.isEmpty ? nil : farewellLetter

        modelContext.insert(record)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Phase 1 暂不实现完整错误提示；日志即可
            print("Save failed: \(error)")
        }
    }
}

#Preview {
    AddFarewellView()
        .modelContainer(for: FarewellRecord.self, inMemory: true)
        .environment(\.appTheme, AppTheme(mode: .light))
        .environment(CurrencyManager())
}