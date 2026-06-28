import SwiftUI

/// 全屏沉浸式图片查看器：左右滑页 + 双指缩放/单指平移 + 双击切换 + 保存到相册
struct FullScreenImageViewer: View {
    let filenames: [String]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var savedToast = false

    // 缩放 / 平移状态
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(filenames: [String], initialIndex: Int) {
        self.filenames = filenames
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 左右滑页
            TabView(selection: $currentIndex) {
                ForEach(Array(filenames.enumerated()), id: \.offset) { index, filename in
                    zoomableImageView(for: filename)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onAppear { currentIndex = initialIndex }

            // 顶部工具条
            VStack {
                HStack(spacing: 12) {
                    if filenames.count > 1 {
                        Text("\(currentIndex + 1) / \(filenames.count)")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Button(action: saveCurrentImage) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Spacer()
            }

            // 保存 toast
            if savedToast {
                Text("已保存到相册")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 60)
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - 单张可缩放图片

    @ViewBuilder
    private func zoomableImageView(for filename: String) -> some View {
        if let image = ImageStore.loadImage(filename: filename) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .highPriorityGesture(zoomGesture.simultaneously(with: panGesture))
                .onTapGesture(count: 2, perform: handleDoubleTap)
        } else {
            ContentUnavailableView(
                "照片已丢失",
                systemImage: "exclamationmark.triangle",
                description: Text("文件可能已被移除")
            )
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 手势

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: scale > 1 ? 0 : 1000)
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.3)) {
            if scale > 1 {
                scale = 1
                lastScale = 1
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2
                lastScale = 2
            }
        }
    }

    // MARK: - 保存到相册

    private func saveCurrentImage() {
        guard currentIndex < filenames.count,
              let image = ImageStore.loadImage(filename: filenames[currentIndex])
        else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedToast = false }
        }
    }
}