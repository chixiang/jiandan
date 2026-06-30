import SwiftUI

struct SharePreviewView: View {
    let record: FarewellRecord
    let onClose: () -> Void

    @State private var selectedTheme: AppThemeMode = .light
    @State private var cachedImages: [AppThemeMode: UIImage] = [:]
    @State private var isReady = false
    @State private var toastMessage: String?
    @State private var showPreviewShare = false
    @State private var shareImage: UIImage?

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
                                    .shadow(color: .black.opacity(0.4), radius: 16)
                                    .tag(mode)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: previewHeight)

                    Spacer()

                    HStack(spacing: 16) {
                        saveButton
                        shareButton
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

            if let toast = toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 120)
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .onAppear(perform: generateImages)
        .sheet(isPresented: $showPreviewShare) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var maxCardWidth: CGFloat {
        min(UIScreen.main.bounds.width - 48, 340)
    }

    private var previewHeight: CGFloat {
        guard let size = cachedImages.first?.value.size else { return 400 }
        let aspect = size.width / size.height
        let byWidth = maxCardWidth / aspect
        let bySafe = UIScreen.main.bounds.height * 0.6
        return min(byWidth, bySafe)
    }

    private var saveButton: some View {
        Button {
            let theme = CardTheme.theme(for: selectedTheme)
            guard let image = FarewellImageGenerator.generate(for: record, theme: theme) else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            withAnimation {
                toastMessage = String(localized: "已保存")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    toastMessage = nil
                }
            }
        } label: {
            Label(String(localized: "保存到相册"), systemImage: "square.and.arrow.down")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
        }
        .foregroundStyle(.white)
    }

    private var shareButton: some View {
        Button {
            shareImage = cachedImages[selectedTheme]
            showPreviewShare = true
        } label: {
            Label(String(localized: "分享"), systemImage: "square.and.arrow.up")
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
