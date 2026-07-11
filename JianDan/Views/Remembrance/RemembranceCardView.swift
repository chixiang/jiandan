import SwiftUI

/// 展示一条 FarewellRecord 的完整信息，照片直接显示在顶部（可左右滑动）。
struct RemembranceCardView: View {
    let record: FarewellRecord
    @Binding var revealedLetterCount: Int

    @Environment(\.appTheme) private var theme
    @Environment(CurrencyManager.self) private var currencyManager

    @State private var currentPhotoIndex = 0

    var onTapPhoto: ((Int) -> Void)? = nil

    private var model: RemembranceCardModel { RemembranceCardModel(record: record) }

    var body: some View {
        VStack(spacing: .md) {
            if model.showsPhotoHint {
                photoCarousel
                    .onTapGesture { onTapPhoto?(currentPhotoIndex) }
            }
            nameSection
            dateSection
            divider
            pillsSection
            if model.showsRecipientDetail { recipientDetailSection }
            if model.showsEmotion { emotionSection }
            divider
            if model.showsLetter {
                letterSection
                divider
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .screenPadding)
    }

    // MARK: - Sections

    @ViewBuilder
    private var photoCarousel: some View {
        if let first = record.photoFilenames.first,
           ImageStore.loadImage(filename: first) != nil {
            TabView(selection: $currentPhotoIndex) {
                ForEach(Array(record.photoFilenames.enumerated()), id: \.offset) { idx, filename in
                    if let image = ImageStore.loadImage(filename: filename) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .tag(idx)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: record.photoFilenames.count > 1 ? .always : .never))
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }

    private var nameSection: some View {
        Text("「\(record.name)」")
            .appFont(.largeTitle)
            .foregroundStyle(theme.primaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, .xl)
    }

    private var dateSection: some View {
        HStack(spacing: .xs) {
            if model.showsPurchaseDate, let purchase = record.purchaseDate {
                Text(purchase, format: .dateTime.year().month().day())
                Text("~")
            }
            Text(record.farewellDate, format: .dateTime.year().month().day())
            if model.showsCompanionshipDays, let days = record.companionshipDays {
                Text("·")
                Text("陪伴我 \(days) 天")
            }
        }
        .appFont(.caption)
        .foregroundStyle(theme.secondary)
    }

    private var pillsSection: some View {
        HStack(spacing: .xs) {
            pill(record.category.displayName, icon: record.category.iconName)
            pill(record.method.localizedName, icon: record.method.icon)
            if model.showsPrice, let price = record.purchasePrice {
                pill(String(format: "%.2f", price),
                     icon: currencyManager.currency.icon)
            }
        }
    }

    private var recipientDetailSection: some View {
        Label(record.recipientDetail ?? "", systemImage: "arrow.right")
            .appFont(.caption)
            .foregroundStyle(theme.secondary)
    }

    private var emotionSection: some View {
        HStack(spacing: .xs) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= (record.emotionValue ?? 0) ? theme.accent : theme.divider)
                    .frame(width: 8, height: 8)
            }
            if let v = record.emotionValue { emotionLabel(v) }
        }
    }

    private var letterSection: some View {
        revealedLetter("\u{201C}\(record.farewellLetter ?? "")\u{201D}")
            .appFont(.letter)
            .lineSpacing(8)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(width: 24, height: 0.5)
    }

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).appFont(.caption)
            Text(text).appFont(.caption)
        }
        .foregroundStyle(theme.secondary)
        .padding(.horizontal, .sm)
        .padding(.vertical, 5)
        .background(theme.cardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(theme.divider, lineWidth: 0.5))
    }

    private func emotionLabel(_ v: Int) -> some View {
        let label: String
        switch v {
        case 1: label = String(localized: "平静")
        case 2: label = String(localized: "复杂")
        case 3: label = String(localized: "不舍")
        default: label = ""
        }
        return Text(label).appFont(.caption).foregroundStyle(theme.secondary).padding(.leading, 4)
    }

    private func revealedLetter(_ text: String) -> Text {
        var attr = AttributedString(text)
        for (index, _) in attr.characters.enumerated() {
            let start = attr.index(attr.startIndex, offsetByCharacters: index)
            let end = attr.index(afterCharacter: start)
            attr[start..<end].foregroundColor = index < revealedLetterCount
                ? theme.primaryText
                : theme.primaryText.opacity(0)
        }
        return Text(attr)
    }
}
