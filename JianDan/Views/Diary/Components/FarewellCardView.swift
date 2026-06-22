import SwiftUI

/// 告别卡片：拍立得风格
struct FarewellCardView: View {
    let record: FarewellRecord

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 主照片
            PhotoThumbView(
                data: record.photoData.first,
                category: record.category,
                size: 88
            )

            VStack(alignment: .leading, spacing: 6) {
                // 名称
                Text(record.name)
                    .font(.headline)
                    .lineLimit(2)

                // 分类 + 方式
                HStack(spacing: 8) {
                    Label(record.category.rawValue, systemImage: record.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(record.method.rawValue, systemImage: record.method.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 日期
                Text(record.farewellDate, format: .dateTime.year().month().day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                // 情感值（可选）
                if let emotion = record.emotionValue {
                    EmotionDotsView(value: emotion)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// 情感值显示（5 个小圆点）
struct EmotionDotsView: View {
    let value: Int  // 1-5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < value ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // 用临时 record（Task 3 的模型接受基础 init）
        let record = FarewellRecord(
            name: "一件蓝色羊毛大衣",
            category: .clothing,
            method: .donate
        )
        FarewellCardView(record: record)
    }
    .padding()
}
