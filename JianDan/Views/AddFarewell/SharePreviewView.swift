import SwiftUI

struct SharePreviewView: View {
    let record: FarewellRecord
    let onSave: (AppThemeMode) -> Void
    let onShare: (UIImage) -> Void
    let onClose: () -> Void

    @State private var selectedTheme: AppThemeMode = .light
    @State private var cachedImages: [AppThemeMode: UIImage] = [:]
    @State private var isReady = false

    private let cardW: CGFloat = 390
    private let cardH: CGFloat = 585

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            if isReady {
                VStack(spacing: 12) {
                    Spacer()

                    TabView(selection: $selectedTheme) {
                        ForEach(AppThemeMode.allCases) { mode in
                            if let image = cachedImages[mode] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: maxCardWidth)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.4), radius: 16)
                                    .tag(mode)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: previewHeight)

                    Spacer()

                    HStack(spacing: 16) {
                        actionButton(label: String(localized: "保存到相册"), icon: "square.and.arrow.down") {
                            onSave(selectedTheme)
                        }
                        actionButton(label: String(localized: "分享"), icon: "square.and.arrow.up") {
                            if let image = cachedImages[selectedTheme] {
                                onShare(image)
                            }
                        }
                    }

                    Button(String(localized: "关闭"), role: .cancel) { onClose() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                }
                .padding(.vertical, 60)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear(perform: generateImages)
    }

    private var maxCardWidth: CGFloat {
        min(UIScreen.main.bounds.width - 48, 340)
    }

    private var previewHeight: CGFloat {
        let byWidth = maxCardWidth * cardH / cardW
        let bySafe = UIScreen.main.bounds.height * 0.6
        return min(byWidth, bySafe)
    }

    private func actionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
        }
        .foregroundStyle(.white)
    }

    private func generateImages() {
        Task { @MainActor in
            var images: [AppThemeMode: UIImage] = [:]
            for mode in AppThemeMode.allCases {
                let theme = CardTheme.theme(for: mode)
                images[mode] = FarewellImageGenerator.generate(for: record, theme: theme)
            }
            cachedImages = images
            isReady = true
        }
    }
}
