import SwiftUI
import UIKit

// MARK: - Card Theme

struct CardTheme {
    let background: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let divider: Color

    static let light = CardTheme(
        background: Color(red: 0.98, green: 0.97, blue: 0.96),
        textPrimary: Color(red: 0.24, green: 0.24, blue: 0.24),
        textSecondary: Color(red: 0.54, green: 0.54, blue: 0.54),
        accent: Color(red: 0.79, green: 0.65, blue: 0.48),
        divider: Color(red: 0.90, green: 0.88, blue: 0.85)
    )

    static let dark = CardTheme(
        background: Color(red: 0.10, green: 0.10, blue: 0.10),
        textPrimary: Color(red: 0.96, green: 0.94, blue: 0.91),
        textSecondary: Color(red: 0.54, green: 0.54, blue: 0.54),
        accent: Color(red: 0.48, green: 0.66, blue: 0.63),
        divider: Color(red: 0.25, green: 0.25, blue: 0.25)
    )

    static let ink = CardTheme(
        background: .black,
        textPrimary: Color(red: 0.96, green: 0.94, blue: 0.91),
        textSecondary: Color(red: 0.43, green: 0.43, blue: 0.43),
        accent: Color(red: 0.70, green: 0.23, blue: 0.28),
        divider: Color(red: 0.20, green: 0.20, blue: 0.20)
    )

    static func theme(for mode: AppThemeMode) -> CardTheme {
        switch mode {
        case .light: return .light
        case .dark: return .dark
        case .ink: return .ink
        }
    }
}

// MARK: - Card View

struct FarewellShareCard: View {
    let name: String
    let categoryDisplayName: String
    let methodDisplayName: String
    let farewellDate: Date
    let purchaseDate: Date?
    let companionshipDays: Int?
    let emotionValue: Int?
    let farewellLetter: String?
    let photoImage: UIImage?
    let theme: CardTheme
    let cardSize: CGSize
    let hasRealPhoto: Bool

    private var shouldUseLandscapeBody: Bool {
        guard let img = photoImage else { return false }
        return !hasRealPhoto || img.size.height > img.size.width
    }

    var body: some View {
        Group {
            if shouldUseLandscapeBody, let img = photoImage {
                landscapeBody(photo: img)
            } else {
                portraitBody
            }
        }
        .overlay(matBorder)
    }

    // MARK: - Landscape (585×390, photo left + text right)

    private func landscapeBody(photo: UIImage) -> some View {
        HStack(spacing: 0) {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 240, maxHeight: 310)
                .shadow(color: theme.textPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.leading, 28)
                .padding(.trailing, 12)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(Font.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Color.clear.frame(height: 10)

                tagsText

                infoText
                    .padding(.top, 4)

                if let value = emotionValue {
                    emotionDots(value: value)
                        .padding(.top, 6)
                }

                if let letter = farewellLetter, !letter.isEmpty {
                    hairline
                        .padding(.vertical, 16)

                    letterView(letter: letter)
                }

                Spacer(minLength: 0)

                hairline

                footerView
                    .padding(.top, 4)
                    .padding(.bottom, 28)
            }
            .padding(.leading, 24)
            .padding(.trailing, 28)
            .padding(.top, 48)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(theme.background)
    }

    // MARK: - Portrait (390×585, centered)

    @ViewBuilder
    private var portraitBody: some View {
        VStack(spacing: 0) {
            if let img = photoImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 326, maxHeight: 240)
                    .shadow(color: theme.textPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.top, 32)
                    .padding(.horizontal, 32)

                Color.clear.frame(height: 24)
            } else {
                Color.clear.frame(height: 56)
            }

            VStack(spacing: 0) {
                Text(name)
                    .font(Font.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Color.clear.frame(height: 10)

                tagsText

                infoText
                    .padding(.top, 4)

                if let value = emotionValue {
                    emotionDots(value: value)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 32)

            hairline
                .padding(.horizontal, 32)
                .padding(.top, 16)

            if let letter = farewellLetter, !letter.isEmpty {
                letterView(letter: letter)
                    .padding(.horizontal, 32)
                    .padding(.top, 14)
            }

            Spacer(minLength: 0)

            hairline
                .padding(.horizontal, 32)

            footerView
                .padding(.horizontal, 32)
                .padding(.top, 4)
                .padding(.bottom, 32)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(theme.background)
    }

    // MARK: - Mat Border

    @ViewBuilder
    private var matBorder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(theme.divider, lineWidth: 0.5)
                .padding(10)
            RoundedRectangle(cornerRadius: 2)
                .stroke(theme.divider, lineWidth: 0.5)
                .padding(14)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Sub-views

    private var tagsText: some View {
        HStack(spacing: 0) {
            Text(categoryDisplayName)
                .font(Font.system(size: 9, weight: .light, design: .default))
                .tracking(2)
                .foregroundStyle(theme.textSecondary)

            Text("  ·  ")
                .font(Font.system(size: 8, weight: .light))
                .foregroundStyle(theme.textSecondary.opacity(0.4))

            Text(methodDisplayName)
                .font(Font.system(size: 9, weight: .light, design: .default))
                .tracking(2)
                .foregroundStyle(theme.textSecondary)
        }
    }

    private var infoText: some View {
        HStack(spacing: 0) {
            if let purchase = purchaseDate {
                Text(dateStringDot(from: purchase))
            } else {
                Text("某天")
            }
            Text(" ~ ")
            Text(dateStringDot(from: farewellDate))

            if let days = companionshipDays {
                Text("  ·  ")
                    .font(Font.system(size: 7))
                    .foregroundStyle(theme.textSecondary.opacity(0.3))

                Text("陪伴我 \(days) 天")
            }
        }
        .font(Font.system(size: 8, weight: .light, design: .default))
        .foregroundStyle(theme.textSecondary.opacity(0.7))
    }

    private func emotionDots(value: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(1...3, id: \.self) { i in
                Text(i <= value ? "●" : "○")
                    .font(Font.system(size: 7))
                    .foregroundStyle(i <= value ? theme.accent : theme.textSecondary.opacity(0.25))
            }
        }
    }

    private var hairline: some View {
        theme.divider
            .frame(height: 0.5)
    }

    private func letterView(letter: String) -> some View {
        HStack(spacing: 0) {
            Text("\"")
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.5))

            Text(letter.prefix(120) + (letter.count > 120 ? "…" : ""))
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
                .lineSpacing(4)

            Text("\"")
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.5))
        }
    }

    private var footerView: some View {
        VStack(spacing: 4) {
            Text("告别清单 · Farewell List")
                .font(Font.system(size: 7, weight: .light, design: .default))
                .tracking(2)
                .foregroundStyle(theme.textSecondary.opacity(0.5))

            Text(dateStringDot(from: .now))
                .font(Font.system(size: 7, weight: .light, design: .default))
                .foregroundStyle(theme.textSecondary.opacity(0.35))
        }
    }

    private func dateStringDot(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d"
        return f.string(from: date)
    }
}

// MARK: - Placeholder Quote Image

struct PlaceholderQuoteView: View {
    let quoteText: String
    let attribution: String
    let theme: CardTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("\"")
                .font(Font.system(size: 12, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.35))

            Text(quoteText)
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)

            Text("\"")
                .font(Font.system(size: 12, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.35))
                .padding(.top, 2)

            Text(attribution)
                .font(Font.system(size: 8, design: .serif).italic())
                .foregroundStyle(theme.textSecondary.opacity(0.45))
                .padding(.top, 6)

            Spacer()
        }
        .frame(width: 360, height: 240)
        .background(theme.background)
    }
}

// MARK: - Image Generator

enum FarewellImageGenerator {
    @MainActor static func generate(for record: FarewellRecord, theme: CardTheme) -> UIImage? {
        let realPhoto: UIImage? = {
            guard let filename = record.photoFilenames.first else { return nil }
            return ImageStore.loadImage(filename: filename)
        }()

        let photoImage: UIImage?
        let cardSize: CGSize

        if let img = realPhoto {
            photoImage = img
            cardSize = img.size.height > img.size.width
                ? CGSize(width: 585, height: 390)
                : CGSize(width: 390, height: 585)
        } else {
            let repo = QuoteRepository()
            let quote = repo.randomQuote()
            let lang = currentLanguage()
            let text = quote?.localizedText(for: lang) ?? ""
            let attribution = quote?.localizedAttribution(for: lang) ?? ""
            photoImage = Self.generatePlaceholderImage(text: text, attribution: attribution, theme: theme)
            cardSize = CGSize(width: 585, height: 390)
        }

        let view = FarewellShareCard(
            name: record.name,
            categoryDisplayName: record.category.displayName,
            methodDisplayName: record.method.localizedName,
            farewellDate: record.farewellDate,
            purchaseDate: record.purchaseDate,
            companionshipDays: record.companionshipDays,
            emotionValue: record.emotionValue,
            farewellLetter: record.farewellLetter,
            photoImage: photoImage,
            theme: theme,
            cardSize: cardSize,
            hasRealPhoto: realPhoto != nil
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return nil }
        let opaque = UIGraphicsImageRenderer(size: uiImage.size).image { _ in
            uiImage.draw(at: .zero)
        }
        return opaque
    }

    private static func currentLanguage() -> AppLanguage {
        let raw = UserDefaults.standard.string(forKey: "app.language")
        let saved = raw.flatMap(AppLanguage.init(rawValue:)) ?? .system
        return saved.resolvedForCurrentSystem
    }

    @MainActor static func generatePlaceholderImage() -> UIImage? {
        let repo = QuoteRepository()
        let quote = repo.randomQuote()
        let lang = currentLanguage()
        let text = quote?.localizedText(for: lang) ?? ""
        let attribution = quote?.localizedAttribution(for: lang) ?? ""
        return generatePlaceholderImage(text: text, attribution: attribution, theme: .light)
    }

    @MainActor private static func generatePlaceholderImage(text: String, attribution: String, theme: CardTheme) -> UIImage? {
        let view = PlaceholderQuoteView(quoteText: text, attribution: attribution, theme: theme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
