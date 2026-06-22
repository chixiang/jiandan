import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("我的\n（待 Task 12 实现）")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .navigationTitle("我的")
        }
    }
}

#Preview {
    ProfileView()
}