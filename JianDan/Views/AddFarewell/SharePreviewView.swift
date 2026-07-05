import SwiftUI

struct SharePreviewView: View {
    let record: FarewellRecord
    let onClose: () -> Void

    @State private var polaroidImage: UIImage? = nil
    @State private var isReady = false
    @State private var toastMessage: String?
    @State private var showSystemShare = false

    private let cardSize = CGSize(width: 360, height: 540)

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            if isReady, let image = polaroidImage {
                VStack(spacing: 16) {
                    Spacer()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: displayWidth)
                        //.shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)

                    Spacer()

                    HStack(spacing: 16) {
                        saveButton
                        shareButton
                    }

                    Button(String(localized: "关闭"), role: .cancel) { onClose() }
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54))
                        .padding(.top, 4)
                }
                .padding(.vertical, 60)
            } else {
                ProgressView()
                    .tint(Color(red: 0.54, green: 0.54, blue: 0.54))
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
        .onAppear(perform: generateImage)
        .sheet(isPresented: $showSystemShare) {
            if let image = polaroidImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var displayWidth: CGFloat {
        let maxW = UIScreen.main.bounds.width * 0.88
        let maxH = UIScreen.main.bounds.height * 0.55
        let ratio = cardSize.width / cardSize.height
        return min(maxW, maxH * ratio)
    }

    private var saveButton: some View {
        Button {
            guard let image = polaroidImage else { return }
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
                .background(Color(red: 0.24, green: 0.24, blue: 0.24).opacity(0.08))
                .clipShape(Capsule())
        }
        .foregroundStyle(Color(red: 0.24, green: 0.24, blue: 0.24))
    }

    private var shareButton: some View {
        Button {
            showSystemShare = true
        } label: {
            Label(String(localized: "分享"), systemImage: "square.and.arrow.up")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.24, green: 0.24, blue: 0.24).opacity(0.08))
                .clipShape(Capsule())
        }
        .foregroundStyle(Color(red: 0.24, green: 0.24, blue: 0.24))
    }

    private func generateImage() {
        Task { @MainActor in
            polaroidImage = FarewellImageGenerator.generate(for: record, theme: .light)
            isReady = true
        }
    }
}
