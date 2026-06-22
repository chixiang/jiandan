import SwiftUI

/// 告别日记空状态
struct DiaryEmptyView: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("还没有告别")
                    .font(.title2)
                Text("挑一件物品，给它写一段告别信")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddTapped) {
                Label("开始第一次告别", systemImage: "plus.circle.fill")
                    .font(.body)
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
