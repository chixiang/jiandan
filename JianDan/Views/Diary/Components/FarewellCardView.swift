import SwiftUI

/// 告别卡片：拍立得风格
struct FarewellCardView: View {
    let record: FarewellRecord

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d"
        return f
    }()

    private static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 主照片
            PhotoThumbView(
                filename: record.photoFilenames.first,
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
                    Label(record.category.displayName, systemImage: record.category.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(record.method.rawValue, systemImage: record.method.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 日期：购入 ~ 减单
                HStack(spacing: 4) {
                    if let purchase = record.purchaseDate {
                        Text(Self.dateString(from: purchase))
                    } else {
                        Text("某天")
                    }
                    Text("~")
                    Text(Self.dateString(from: record.farewellDate))
                }
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

/// 情感值显示（3 个小圆点）
struct EmotionDotsView: View {
    let value: Int  // 1-3

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
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
            category: .builtin(.clothing),
            method: .donate
        )
        FarewellCardView(record: record)
    }
    .padding()
}
