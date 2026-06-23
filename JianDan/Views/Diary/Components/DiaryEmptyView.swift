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
                Text("还没有减单")
                    .font(.title2)
                Text("拥有的愈少，\n自由便愈多")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddTapped) {
                Label("记下第一件", systemImage: "plus.circle.fill")
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
