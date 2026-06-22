import SwiftUI

struct DiaryView: View {
    var body: some View {
        NavigationStack {
            Text("告别日记\n（待 Task 6 实现）")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .navigationTitle("告别")
        }
    }
}

#Preview {
    DiaryView()
}