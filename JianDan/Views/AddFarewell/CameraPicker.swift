import SwiftUI
import AVFoundation
import UIKit

/// 自定义相机 — 拍摄时显示方形取景框，拍完后自动裁切为正方形
///
/// 使用 AVFoundation，预览画面即时显示半透明遮罩 + 白线方框。
/// 按快门后中心裁切为 1920×1920 正方形 JPEG，自动返回。
struct SquareCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (Data) -> Void
    @StateObject private var model = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(session: model.session)
                .ignoresSafeArea()

            if let preview = model.capturedImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            GeometryReader { geo in
                let cropSize = geo.size.width
                CameraCropOverlay(cropSize: cropSize)
            }
            .allowsHitTesting(false)

            VStack {
                Spacer()
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(20)
                        }
                        Spacer()
                    }

                    Button(action: { model.capture() }) {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.4), lineWidth: 4)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(model.$capturedData) { data in
            guard let data else { return }
            onCapture(data)
            dismiss()
        }
    }
}

// MARK: - Camera Model

private final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var capturedData: Data?
    @Published var capturedImage: UIImage?

    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.session", qos: .userInitiated)

    override init() {
        super.init()
        queue.async { [weak self] in
            self?.setupCamera()
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        session.startRunning()
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        // Step 1: 立即在主线程显示原始图片 → 画面瞬间冻结
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
        }

        // Step 2: 后台裁切
        let side = min(image.size.width, image.size.height)
        let scale = 1920 / side
        let offsetX = -(image.size.width - side) / 2 * scale
        let offsetY = -(image.size.height - side) / 2 * scale

        DispatchQueue.global(qos: .userInitiated).async {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1920))
            let cropped = renderer.image { _ in
                image.draw(in: CGRect(x: offsetX, y: offsetY,
                                      width: image.size.width * scale,
                                      height: image.size.height * scale))
            }

            let jpeg = cropped.jpegData(compressionQuality: 0.85)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.session.stopRunning()
                self.capturedImage = cropped
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.capturedData = jpeg
                }
            }
        }
    }
}

// MARK: - Camera Preview

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        PreviewView(session: session)
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

private final class PreviewView: UIView {
    private let previewLayer = AVCaptureVideoPreviewLayer()

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspect
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - Square Overlay

private struct CameraCropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            let cropX = (geo.size.width - cropSize) / 2
            let cropY = (geo.size.height - cropSize) / 2

            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addRect(CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize))
            }
            .fill(Color.black.opacity(0.35), style: FillStyle(eoFill: true))
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            )
        }
    }
}
