import SwiftUI

/// 情感值选择（1-3，圆点 + 标签，可重选为未选）
struct EmotionStarsView: View {
    @Binding var value: Int?  // nil 表示未选

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Button {
                        value = (value == i) ? nil : i
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(i <= (value ?? 0) ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 16, height: 16)
                            Text(label(for: i))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if value == nil {
                Text("（点击选择）")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func label(for value: Int) -> String {
        switch value {
        case 1: return String(localized: "平静")
        case 2: return String(localized: "复杂")
        case 3: return String(localized: "不舍")
        default: return ""
        }
    }
}

#Preview {
    @Previewable @State var value: Int? = 2
    return EmotionStarsView(value: $value)
        .padding()
}
