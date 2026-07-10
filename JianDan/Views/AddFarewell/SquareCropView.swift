import SwiftUI

/// 正方形裁切界面
///
/// 全屏展示用户选择的图片，提供方形取景框（白线边框 + 区域外半透明遮罩），
/// 用户通过双指缩放 + 拖动调整图片在取景框内的位置，确认后输出 1920×1920 正方形 JPEG。
struct SquareCropView: View {
    let image: UIImage
    let onCrop: (Data) -> Void
    let onCancel: () -> Void

    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var lastDragOffset: CGSize = .zero

    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0

    var body: some View {
        GeometryReader { geo in
            let cropSize = min(geo.size.width * 0.9, geo.size.height * 0.65)
            let fitScale = min(cropSize / image.size.width, cropSize / image.size.height)
            let dW = image.size.width * fitScale
            let dH = image.size.height * fitScale

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .offset(dragOffset)
                    .frame(width: cropSize, height: cropSize)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastZoomScale * value
                                zoomScale = min(max(newScale, minZoom), maxZoom)
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = CGSize(
                                    width: lastDragOffset.width + value.translation.width,
                                    height: lastDragOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastDragOffset = dragOffset
                            }
                    )

                CropDimmingOverlay(cropSize: cropSize)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button(action: onCancel) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { cropAndConfirm(cropSize: cropSize, displayW: dW, displayH: dH) }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                }

                VStack {
                    Spacer()
                    Text("移动和缩放图片以调整裁切区域")
                        .foregroundStyle(.white.opacity(0.5))
                        .appFont(.caption)
                        .padding(.bottom, 60)
                }
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
    }

    private func cropAndConfirm(cropSize: CGFloat, displayW: CGFloat, displayH: CGFloat) {
        let pixelScale = 1920 / cropSize
        let zoomedW = displayW * zoomScale * pixelScale
        let zoomedH = displayH * zoomScale * pixelScale
        let offsetX = dragOffset.width * pixelScale
        let offsetY = dragOffset.height * pixelScale

        let drawX = (1920 - zoomedW) / 2 + offsetX
        let drawY = (1920 - zoomedH) / 2 + offsetY

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1920), format: format)
        let output = renderer.image { _ in
            image.draw(in: CGRect(x: drawX, y: drawY, width: zoomedW, height: zoomedH))
        }

        guard let data = output.jpegData(compressionQuality: 0.85) else { return }
        onCrop(data)
    }
}

private struct CropDimmingOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            let cropX = (geo.size.width - cropSize) / 2
            let cropY = (geo.size.height - cropSize) / 2

            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addRect(CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize))
            }
            .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: cropSize, height: cropSize)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            )
        }
    }
}

#Preview {
    SquareCropView(
        image: UIImage(systemName: "photo")!,
        onCrop: { _ in },
        onCancel: {}
    )
}
