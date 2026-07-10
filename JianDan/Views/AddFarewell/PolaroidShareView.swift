import SwiftUI

/// 拍立得分享视图 — 通用组件。
/// - `animateDevelop == true`: 从屏幕底部上浮 + 照片显影（用于新建保存后）
/// - `animateDevelop == false`: 跳过动画，立即静止展示（用于详情页直接进入）
struct PolaroidShareView: View {
    let record: FarewellRecord
    let animateDevelop: Bool
    let onClose: () -> Void

    @Environment(\.appTheme) private var theme

    @State private var ceremonyPhoto: UIImage?
    @State private var phase: Phase = .hidden
    @State private var polaroidOffset: CGFloat = UIScreen.main.bounds.height
    @State private var photoBlurRadius: CGFloat = 20
    @State private var toastMessage: String?
    @State private var showSystemShare = false
    @State private var shareImage: UIImage?

    private enum Phase { case hidden, developing, ready }

    var body: some View {
        ZStack {
            theme.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    if phase == .ready { onClose() }
                }

            VStack(spacing: .md) {
                Spacer()

                polaroidCard
                    .offset(y: polaroidOffset)

                if phase == .ready {
                    HStack(spacing: 16) {
                        saveButton
                        shareButton
                    }
                    .transition(.opacity)

                    Button("关闭", role: .cancel) { onClose() }
                        .foregroundStyle(theme.secondary)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.vertical, 60)

            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
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
        .onAppear(perform: handleAppear)
        .sheet(isPresented: $showSystemShare) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Polaroid Card

    @ViewBuilder
    private var polaroidCard: some View {
        VStack(spacing: 0) {
            let photoW: CGFloat = 320 * 0.9
            let photoH: CGFloat = photoW

            if let photo = ceremonyPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoW, height: photoH)
                    .clipped()
                    .blur(radius: photoBlurRadius)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
            } else {
                Rectangle()
                    .fill(Color(red: 0.90, green: 0.88, blue: 0.85))
                    .frame(width: photoW, height: photoH)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
            }

            Text(record.name)
                .appFont(.title)
                .foregroundStyle(Color(red: 0.24, green: 0.24, blue: 0.24))
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            if let days = record.companionshipDays {
                Text("陪伴我 \(days) 天")
                    .font(Font.system(size: 10, weight: .light))
                    .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54))
                    .padding(.top, 6)
            }

            if let letter = record.farewellLetter, !letter.isEmpty {
                HStack(spacing: 0) {
                    Text("\"")
                        .font(Font.system(size: 10, design: .serif).italic())
                        .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                    Text(letter)
                        .font(Font.system(size: 10, design: .serif).italic())
                        .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54))
                        .lineLimit(2)
                        .lineSpacing(4)
                    Text("\"")
                        .font(Font.system(size: 10, design: .serif).italic())
                        .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                }
                .padding(.top, 10)
                .padding(.horizontal, 24)
            }

            Spacer()

            Color(red: 0.90, green: 0.88, blue: 0.85)
                .frame(height: 0.5)
                .padding(.horizontal, 24)

            HStack(alignment: .bottom) {
                Text("app_display_name")
                    .font(Font.system(size: 7, weight: .light))
                    .tracking(2)
                    .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.5))
                Spacer()
                Text(polaroidDateString)
                    .font(Font.system(size: 7, weight: .light))
                    .foregroundStyle(Color(red: 0.54, green: 0.54, blue: 0.54).opacity(0.35))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 320, height: 480)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
    }

    // MARK: - Buttons

    private var saveButton: some View {
        Button {
            guard let image = generatePolaroidImage() else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            withAnimation { toastMessage = String(localized: "已保存") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { toastMessage = nil }
            }
        } label: {
            Label(String(localized: "保存到相册"), systemImage: "square.and.arrow.down")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .foregroundStyle(theme.accent)
    }

    private var shareButton: some View {
        Button {
            guard let image = generatePolaroidImage() else { return }
            shareImage = image
            showSystemShare = true
        } label: {
            Label(String(localized: "分享"), systemImage: "square.and.arrow.up")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .foregroundStyle(theme.accent)
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        loadPhoto()

        if animateDevelop {
            phase = .developing
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                polaroidOffset = 0
            }
            withAnimation(.easeOut(duration: 3.0).delay(0.2)) {
                photoBlurRadius = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .ready
                }
            }
        } else {
            polaroidOffset = 0
            photoBlurRadius = 0
            phase = .ready
        }
    }

    private func loadPhoto() {
        if let filename = record.photoFilenames.first {
            ceremonyPhoto = ImageStore.loadImage(filename: filename)
        }
    }

    private var polaroidDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d"
        return f.string(from: .now)
    }

    private func generatePolaroidImage() -> UIImage? {
        FarewellImageGenerator.generate(for: record, theme: .light)
    }
}