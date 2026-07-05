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

// MARK: - Polaroid Card View

struct FarewellShareCard: View {
    let name: String
    let companionshipDays: Int?
    let farewellLetter: String?
    let photoImage: UIImage?

    // Polaroid white card — hardcoded
    private let cardBg = Color.white
    private let textPrimary = Color(red: 0.24, green: 0.24, blue: 0.24)
    private let textSecondary = Color(red: 0.54, green: 0.54, blue: 0.54)
    private let divider = Color(red: 0.90, green: 0.88, blue: 0.85)
    private let cardW: CGFloat = 360
    private let cardH: CGFloat = 540

    private var isPhotoLandscape: Bool {
        guard let img = photoImage else { return true }
        return img.size.width > img.size.height
    }

    private var photoSideMargin: CGFloat { cardW * 0.05 }
    private var photoTopMargin: CGFloat { photoSideMargin + (isPhotoLandscape ? 16 : 0) }
    private var photoW: CGFloat { cardW - photoSideMargin * 2 }
    private var photoH: CGFloat {
        isPhotoLandscape ? photoW * 3 / 4 : min(photoW * 4 / 3, cardH * 0.65)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo area
            if let img = photoImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoW, height: photoH)
                    .clipped()
                    .padding(.top, photoTopMargin)
                    .padding(.horizontal, photoSideMargin)
            }

            // Name
            Text(name)
                .font(AppTypography.title.font)
                .foregroundStyle(textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            // Companionship days
            if let days = companionshipDays {
                Text("陪伴我 \(days) 天")
                    .font(Font.system(size: 10, weight: .light))
                    .foregroundStyle(textSecondary)
                    .padding(.top, 6)
            }

            // Letter
            if let letter = farewellLetter, !letter.isEmpty {
                letterView(letter: letter)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            // Footer
            divider.frame(height: 0.5)
                .padding(.horizontal, 24)

            HStack(alignment: .bottom) {
                Text("告别清单 · Farewell List")
                    .font(Font.system(size: 7, weight: .light))
                    .tracking(2)
                    .foregroundStyle(textSecondary.opacity(0.5))
                Spacer()
                Text(dateStringDot(from: .now))
                    .font(Font.system(size: 7, weight: .light))
                    .foregroundStyle(textSecondary.opacity(0.35))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: cardW, height: cardH)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - Sub-views

    private func letterView(letter: String) -> some View {
        HStack(spacing: 0) {
            Text("\"")
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(textSecondary.opacity(0.5))
            Text(letter.prefix(120) + (letter.count > 120 ? "…" : ""))
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(textSecondary)
                .lineLimit(2)
                .lineSpacing(4)
            Text("\"")
                .font(Font.system(size: 10, design: .serif).italic())
                .foregroundStyle(textSecondary.opacity(0.5))
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
    @MainActor static func generate(for record: FarewellRecord, theme: CardTheme, floating: Bool = true) -> UIImage? {
        let realPhoto: UIImage? = {
            guard let filename = record.photoFilenames.first else { return nil }
            return ImageStore.loadImage(filename: filename)
        }()

        let photoImage: UIImage?
        if let img = realPhoto {
            photoImage = img
        } else {
            let repo = QuoteRepository()
            let quote = repo.randomQuote()
            let lang = currentLanguage()
            let text = quote?.localizedText(for: lang) ?? ""
            let attribution = quote?.localizedAttribution(for: lang) ?? ""
            photoImage = Self.generatePlaceholderImage(text: text, attribution: attribution, theme: theme)
        }

        let card = FarewellShareCard(
            name: record.name,
            companionshipDays: record.companionshipDays,
            farewellLetter: record.farewellLetter,
            photoImage: photoImage
        )

        let baseView: AnyView
        if floating {
            baseView = AnyView(
                ZStack {
                    Color.white
                    card
                        .padding(40)
                }
                .frame(width: 440, height: 620)
            )
        } else {
            baseView = AnyView(card)
        }

        let renderer = ImageRenderer(content: baseView)
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return nil }
        let opaque = UIGraphicsImageRenderer(size: uiImage.size).image { _ in
            uiImage.draw(at: CGPoint.zero)
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
