import SwiftUI

/// 告别日记空状态
struct DiaryEmptyView: View {
    @Environment(\.appTheme) private var theme
    let onAddTapped: () -> Void

    @State private var isFloating = false
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
                .offset(y: isFloating ? -6 : 6)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: isFloating
                )

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
            .scaleEffect(isBreathing ? 1.04 : 1.0)
            .animation(
                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: isBreathing
            )

            Spacer()
        }
        .padding()
        .onAppear {
            isFloating = true
            isBreathing = true
        }
    }
}

#Preview {
    DiaryEmptyView(onAddTapped: {})
}
