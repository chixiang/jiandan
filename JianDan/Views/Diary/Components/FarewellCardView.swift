import SwiftUI

/// 告别卡片：拍立得风格
struct FarewellCardView: View {
    let record: FarewellRecord

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 主照片
            PhotoThumbView(
                filename: record.photoFilenames.first,
                category: record.category,
                size: 88
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: record.category.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(record.name)
                        .font(.headline)
                        .lineLimit(2)
                }

                // 陪伴天数
                if let days = record.companionshipDays {
                    Text("陪伴我 \(days) 天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
