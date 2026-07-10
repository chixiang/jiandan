import SwiftUI

/// 情感值选择（1-3，圆点 + 标签，可重选为未选）
struct EmotionStarsView: View {
    @Binding var value: Int?  // nil 表示未选
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Button {
                        let newValue = (value == i) ? nil : i
                        value = newValue
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(i <= (value ?? 0) ? theme.accent : theme.divider)
                                .frame(width: 16, height: 16)
                            Text(label(for: i))
                                .appFont(.caption)
                                .foregroundStyle(theme.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value)
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
