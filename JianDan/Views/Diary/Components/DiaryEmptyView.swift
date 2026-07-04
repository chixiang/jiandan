import SwiftUI

/// 告别日记空状态
struct DiaryEmptyView: View {
    @Environment(\.appTheme) private var theme
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(theme.secondary)

            VStack(spacing: 8) {
                Text("还没有告别记录")
                    .appFont(.title)
                Text("拥有的愈少，\n自由便愈多")
                    .appFont(.body)
                    .foregroundStyle(theme.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddTapped) {
                Label("记下第一件", systemImage: "plus.circle.fill")
                    .appFont(.body)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    DiaryEmptyView(onAddTapped: {})
}
