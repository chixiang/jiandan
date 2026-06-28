import SwiftUI
import SwiftData

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
    @State private var purchasePriceText: String = ""
    @State private var recipientDetail: String = ""
    @State private var farewellLetter: String = ""
    @State private var emotionValue: Int? = nil
    @State private var photos: [PhotoItem] = []

    @State private var showPurchaseDate: Bool = false

    @State private var showCeremony = false
    @State private var ceremonyFilled = false
    @State private var savedName = ""
    @State private var ceremonyColor: Color = .clear

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
                        Text("告别留言")
                    } footer: {
                        HStack {
                            Spacer()
                            Text("\(farewellLetter.count) / \(FarewellRecord.farewellLetterMaxLength)")
                                .font(.caption)
                                .foregroundStyle(farewellLetter.count > FarewellRecord.farewellLetterMaxLength * 4 / 5 ? .orange : .secondary)
                        }
                    }
                }
                .navigationTitle("新建告别")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { if !showCeremony { dismiss() } }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("保存") { save() }
                            .disabled(!canSave || showCeremony)
                            .fontWeight(.semibold)
                    }
                }

                if showCeremony {
                    ceremonyOverlay
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }

    @ViewBuilder
    private var ceremonyOverlay: some View {
        ZStack {
            theme.background.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Circle()
                    .stroke(ceremonyColor, lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .fill(ceremonyColor)
                            .scaleEffect(ceremonyFilled ? 1 : 0)
                    )

                Text(savedName)
                    .font(Font.system(.title2, design: .serif))
                    .foregroundStyle(theme.primaryText)

                Text("感谢陪伴")
                    .font(AppTypography.caption)
                    .foregroundStyle(theme.secondary)
            }
        }
        .onTapGesture { dismiss() }
    }

    private func save() {
        guard !showCeremony else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        savedName = trimmedName

        // 把 Data 转 filenames（先存图，再构造 record）
        var savedFilenames: [String] = []
        for photo in photos {
            do {
                let filename = try ImageStore.save(photo.data)
                savedFilenames.append(filename)
            } catch {
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

            ceremonyColor = theme.accent
            withAnimation(.easeOut(duration: 0.4)) {
                showCeremony = true
            }
            withAnimation(.spring(duration: 0.5).delay(0.3)) {
                ceremonyFilled = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch {
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