import SwiftUI

/// 全屏 modal，展示某条告别记录的所有照片。
/// 提供左右翻页、下拉关闭、左上角 × 按钮。
struct PhotoViewerSheet: View {
    let filenames: [String]
    var initialIndex: Int = 0
    let onDismiss: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0

    init(filenames: [String], initialIndex: Int = 0, onDismiss: @escaping () -> Void) {
        self.filenames = filenames
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: max(0, min(initialIndex, filenames.count - 1)))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            if filenames.isEmpty {
                Text("没有照片")
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(filenames.enumerated()), id: \.offset) { idx, name in
                        if let ui = ImageStore.loadImage(filename: name) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .tag(idx)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white.opacity(0.3))
                                .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: filenames.count > 1 ? .always : .never))
                .offset(y: dragOffset)
                .gesture(dragGesture)
            }

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                if v.translation.height > 0 { dragOffset = v.translation.height }
            }
            .onEnded { v in
                if v.translation.height > 120 {
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}
