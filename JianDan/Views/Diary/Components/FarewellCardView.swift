import SwiftUI

/// 告别卡片：拍立得风格
struct FarewellCardView: View {
    let record: FarewellRecord
    @Environment(\.appTheme) private var theme
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 主照片（hero 转场锚点）
            Group {
                if let ns = heroNamespace {
                    PhotoThumbView(
                        filename: record.photoFilenames.first,
                        category: record.category,
                        size: 88
                    )
                    .matchedGeometryEffect(id: record.id.uuidString + "-hero", in: ns)
                } else {
                    PhotoThumbView(
                        filename: record.photoFilenames.first,
                        category: record.category,
                        size: 88
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: record.category.iconName)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.secondary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.name)
                            .font(AppTypography.headline)
                            .lineLimit(2)

                        // 陪伴天数
                        if let days = record.companionshipDays {
                            Text("陪伴我 \(days) 天")
                                .font(AppTypography.caption)
                                .foregroundStyle(theme.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        let record = FarewellRecord(
            name: "一件蓝色羊毛大衣",
            category: .builtin(.clothing),
            method: .donate
        )
        FarewellCardView(record: record)
    }
    .padding()
}
