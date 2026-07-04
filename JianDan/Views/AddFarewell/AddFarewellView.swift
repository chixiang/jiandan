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
    @State private var ceremonyPhoto: UIImage? = nil
    @State private var polaroidOffset: CGFloat = UIScreen.main.bounds.height
    @State private var photoBlurRadius: CGFloat = 20
    @State private var savedName = ""
    @State private var ceremonyDays: Int? = nil
    @State private var ceremonyLetter: String? = nil
    @State private var savedRecord: FarewellRecord?
    @State private var toastMessage: String? = nil
    @State private var showSystemShare = false
    @State private var shareImage: UIImage? = nil

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
                        Toggle("记录获得日期", isOn: $showPurchaseDate)

                        if showPurchaseDate {
                            DatePicker("获得日期", selection: Binding(
                                get: { purchaseDate ?? Date.now.addingTimeInterval(-365 * 86400) },
                                set: { purchaseDate = $0 }
                            ), in: ...farewellDate, displayedComponents: .date)
                        }

                        PriceInputView(price: $purchasePrice, symbol: currencyManager.currency.symbol)

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

                if polaroidPhase != .hidden {
                    polaroidView
                        .transition(.opacity)
                        .zIndex(1)
                }

                if let msg = toastMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.75))
                            .clipShape(Capsule())
                            .padding(.bottom, 120)
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .sensoryFeedback(.success, trigger: polaroidPhase)
        }
    }

    // MARK: - Polaroid

    @ViewBuilder
    private var polaroidView: some View {
        ZStack {
            theme.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    if polaroidPhase == .ready { dismiss() }
                }

            VStack(spacing: .md) {
                Spacer()

                // Polaroid card
                VStack(spacing: 0) {
                    // Photo area
                    let photoW: CGFloat = 320 * 0.9
                    let photoH: CGFloat = {
                        guard let p = ceremonyPhoto else { return photoW * 3 / 4 }
                        return p.size.width > p.size.height
                            ? photoW * 3 / 4
                            : min(photoW * 4 / 3, 480 * 0.65)
                    }()
                    let isPhotoLandscape = ceremonyPhoto.map { $0.size.width > $0.size.height } ?? true
                    let photoTopPad: CGFloat = isPhotoLandscape ? 32 : 16

                    if let photo = ceremonyPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: photoW, height: photoH)
                            .clipped()
                            .blur(radius: photoBlurRadius)
                            .padding(.top, photoTopPad)
                            .padding(.horizontal, 16)
                    } else {
                        Rectangle()
                            .fill(Color(red: 0.90, green: 0.88, blue: 0.85))
                            .frame(width: photoW, height: photoW * 3 / 4)
                            .padding(.top, photoTopPad)
                            .padding(.horizontal, 16)
                    }

                    // Name
                    Text(savedName)
                        .appFont(.title)
                        .foregroundStyle(Color(red: 0.24, green: 0.24, blue: 0.24))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)

                    // Companionship days
                    if let days = ceremonyDays {
                        Text("陪伴我 \(days) 天")
                            .font(Font.system(size: 10, weight: .light))
                            .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54))
                            .padding(.top, 6)
                    }

                    // Farewell letter
                    if let letter = ceremonyLetter, !letter.isEmpty {
                        HStack(spacing: 0) {
                            Text("\"")
                                .font(Font.system(size: 10, design: .serif).italic())
                                .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                            Text(letter)
                                .font(Font.system(size: 10, design: .serif).italic())
                                .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54))
                                .lineLimit(2)
                                .lineSpacing(4)
                            Text("\"")
                                .font(Font.system(size: 10, design: .serif).italic())
                                .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    // Footer
                    Color(red: 0.90, green: 0.88, blue: 0.85)
                        .frame(height: 0.5)
                        .padding(.horizontal, 24)

                    HStack(alignment: .bottom) {
                        Text("告别清单 · Farewell List")
                            .font(Font.system(size: 7, weight: .light))
                            .tracking(2)
                            .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                        Spacer()
                        Text(polaroidDateString)
                            .font(Font.system(size: 7, weight: .light))
                            .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.35))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .frame(width: 320, height: 480)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                .offset(y: polaroidOffset)

                // Save / Share (after development)
                if polaroidPhase == .ready {
                    HStack(spacing: 16) {
                        saveButton
                        shareButton
                    }
                    .transition(.opacity)

                    Button("关闭", role: .cancel) { dismiss() }
                        .foregroundStyle(theme.secondary)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.vertical, 60)
        }
    }

    // MARK: - Helpers

    private var polaroidDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d"
        return f.string(from: .now)
    }

    private func generatePolaroidImage() -> UIImage? {
        guard let record = savedRecord else { return nil }
        return FarewellImageGenerator.generate(for: record, theme: .light)
    }

    private var saveButton: some View {
        Button {
            guard let image = generatePolaroidImage() else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            withAnimation { toastMessage = String(localized: "已保存") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { toastMessage = nil }
            }
        } label: {
            Label(String(localized: "保存到相册"), systemImage: "square.and.arrow.down")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .foregroundStyle(theme.accent)
    }

    private var shareButton: some View {
        Button {
            guard let image = generatePolaroidImage() else { return }
            shareImage = image
            showSystemShare = true
        } label: {
            Label(String(localized: "分享"), systemImage: "square.and.arrow.up")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .foregroundStyle(theme.accent)
        .sheet(isPresented: $showSystemShare) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard polaroidPhase == .hidden else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        savedName = trimmedName

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

        // Load ceremony photo
        if let data = photos.first?.data, let img = UIImage(data: data) {
            ceremonyPhoto = img
        } else if let filename = savedFilenames.first {
            ceremonyPhoto = ImageStore.loadImage(filename: filename)
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
            ceremonyDays = record.companionshipDays
            ceremonyLetter = record.farewellLetter

            polaroidPhase = .developing

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                polaroidOffset = 0
            }
            withAnimation(.easeOut(duration: 3.0).delay(0.2)) {
                photoBlurRadius = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    polaroidPhase = .ready
                }
            }
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