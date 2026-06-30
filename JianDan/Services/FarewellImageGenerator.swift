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
    let categoryIcon: String
    let methodDisplayName: String
    let methodIcon: String
    let farewellDate: Date
    let companionshipDays: Int?
    let emotionValue: Int?
    let farewellLetter: String?
    let photoImage: UIImage?
    let theme: CardTheme

    var body: some View {
        VStack(spacing: 0) {
            if let photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 240)
                    .clipped()
                    .cornerRadius(4)
                    .padding(.top, 20)
            } else {
                Color.clear.frame(height: 20)
            }

            Text(name)
                .font(Font.system(.title2, design: .serif))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, photoImage != nil ? 12 : 28)

            HStack(spacing: 12) {
                tag(icon: categoryIcon, text: categoryDisplayName)
                tag(icon: methodIcon, text: methodDisplayName)
            }
            .font(Font.system(.subheadline))
            .foregroundStyle(theme.textSecondary)
            .padding(.top, 12)

            HStack(spacing: 16) {
                dateLabel
                if let days = companionshipDays {
                    daysLabel(days: days)
                }
                if let value = emotionValue {
                    emotionDots(value: value)
                }
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.top, 8)

            theme.divider
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            if let letter = farewellLetter, !letter.isEmpty {
                VStack(spacing: 4) {
                    Text("\"")
                        .font(Font.system(.title3, design: .serif).italic())
                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(letter.prefix(120) + (letter.count > 120 ? "…" : ""))
                        .font(Font.system(.subheadline, design: .serif).italic())
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)

                    Text("\"")
                        .font(Font.system(.title3, design: .serif).italic())
                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                theme.divider
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                Text("告别清单 · Farewell List")
                    .font(Font.system(.caption2))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))

                Text(dateString(from: .now))
                    .font(Font.system(.caption2))
                    .foregroundStyle(theme.textSecondary.opacity(0.4))
            }
            .padding(.bottom, 20)
        }
        .frame(width: 390, height: 585)
        .background(theme.background)
    }

    private func tag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }

    private var dateLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption)
            Text(dateString(from: farewellDate))
                .font(.caption)
        }
    }

    private func daysLabel(days: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            Text("\(days)天")
                .font(.caption)
        }
    }

    private func emotionDots(value: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Text(i <= value ? "●" : "○")
                    .font(.caption)
                    .foregroundStyle(i <= value ? theme.accent : theme.textSecondary.opacity(0.3))
            }
        }
    }

    private func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d"
        return f.string(from: date)
    }
}

// MARK: - Image Generator

enum FarewellImageGenerator {
    @MainActor static func generate(for record: FarewellRecord, theme: CardTheme) -> UIImage? {
        let photoImage: UIImage? = {
            guard let filename = record.photoFilenames.first else { return nil }
            return ImageStore.loadImage(filename: filename)
        }()

        let view = FarewellShareCard(
            name: record.name,
            categoryDisplayName: record.category.displayName,
            categoryIcon: record.category.iconName,
            methodDisplayName: record.method.localizedName,
            methodIcon: record.method.icon,
            farewellDate: record.farewellDate,
            companionshipDays: record.companionshipDays,
            emotionValue: record.emotionValue,
            farewellLetter: record.farewellLetter,
            photoImage: photoImage,
            theme: theme
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
