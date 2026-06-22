import SwiftUI

struct WisdomView: View {
    var body: some View {
        NavigationStack {
            Text("极简之道\n（待 Task 10 实现）")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .navigationTitle("极简")
        }
    }
}

#Preview {
    WisdomView()
}