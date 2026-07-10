import SwiftUI
import SwiftData

private enum PolaroidPhase {
    case hidden, developing, ready
}

/// 新建告别表单
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
    @State private var purchasePrice: Double? = nil
    @State private var recipientDetail: String = ""
    @State private var farewellLetter: String = ""
    @State private var emotionValue: Int? = nil
    @State private var photos: [PhotoItem] = []

    @State private var showPurchaseDate: Bool = false

    @State private var polaroidPhase: PolaroidPhase = .hidden
    @State private var savedRecord: FarewellRecord?

    private var canSave: Bool {
        AddFarewellValidator.canSave(name: name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
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

                        DatePicker("告别日期", selection: $farewellDate, in: ...Date.now, displayedComponents: .date)
                    }

                    Section("分类") {
                        CategoryPickerSection(selection: $category)
                    }

                    Section("去向") {
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

                    Section("获得") {
                        Toggle("记录获得日期", isOn: $showPurchaseDate)

                        if showPurchaseDate {
                            DatePicker("获得日期", selection: Binding(
                                get: { purchaseDate ?? Date.now.addingTimeInterval(-365 * 86400) },
                                set: { purchaseDate = $0 }
                            ), in: ...farewellDate, displayedComponents: .date)
                        }

                        PriceInputView(price: $purchasePrice, symbol: currencyManager.currency.symbol)
                    }

                    Section("心情") {
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
                        Text("告别留言")
                    } footer: {
                        HStack {
                            Spacer()
                            Text("\(farewellLetter.count) / \(FarewellRecord.farewellLetterMaxLength)")
                                .appFont(.caption)
                                .foregroundStyle(farewellLetter.count > FarewellRecord.farewellLetterMaxLength * 4 / 5 ? .orange : theme.secondary)
                        }
                    }
                }
                .navigationTitle("新建告别")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if polaroidPhase == .hidden {
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

                if polaroidPhase != .hidden, let record = savedRecord {
                    PolaroidShareView(
                        record: record,
                        animateDevelop: true,
                        onClose: { dismiss() }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .sensoryFeedback(.success, trigger: polaroidPhase)
        }
    }

    // MARK: - Save

    private func save() {
        guard polaroidPhase == .hidden else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var savedFilenames: [String] = []
        for photo in photos {
            do {
                let filename = try ImageStore.save(photo.data)
                savedFilenames.append(filename)
            } catch {
            }
        }

        if savedFilenames.isEmpty {
            if let image = FarewellImageGenerator.generatePlaceholderImage(),
               let data = image.jpegData(compressionQuality: 0.85) {
                do {
                    let filename = try ImageStore.save(data)
                    savedFilenames.append(filename)
                } catch {
                }
            }
        }

        let record = FarewellRecord(
            name: trimmedName,
            category: category,
            farewellDate: farewellDate,
            method: method,
            photoFilenames: savedFilenames
        )
        record.purchaseDate = purchaseDate
        record.purchasePrice = purchasePrice
        record.emotionValue = emotionValue
        record.recipientDetail = recipientDetail.isEmpty ? nil : recipientDetail
        record.farewellLetter = farewellLetter.isEmpty ? nil : farewellLetter

        modelContext.insert(record)

        do {
            try modelContext.save()

            savedRecord = record
            polaroidPhase = .ready
        } catch {
        }
    }

}

#Preview {
    AddFarewellView()
        .modelContainer(for: FarewellRecord.self, inMemory: true)
        .environment(\.appTheme, AppTheme(mode: .light))
        .environment(CurrencyManager())
}