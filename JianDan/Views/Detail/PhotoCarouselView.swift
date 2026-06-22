import SwiftUI

/// 多张照片轮播（横向滑动 + 主照片 + 缺图占位）
struct PhotoCarouselView: View {
    let filenames: [String]
    private let height: CGFloat = 240

    var body: some View {
        if filenames.isEmpty {
            // 无照片占位
            ZStack {
                Rectangle()
                    .fill(.tertiary.opacity(0.3))
                Image(systemName: "photo")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.secondary)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            TabView {
                ForEach(Array(filenames.enumerated()), id: \.offset) { _, filename in
                    if let image = ImageStore.loadImage(filename: filename) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                            .clipped()
                    } else {
                        // 图片文件丢失
                        ZStack {
                            Rectangle()
                                .fill(.tertiary.opacity(0.3))
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(.orange)
                                Text("照片已丢失")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: height)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: filenames.count > 1 ? .always : .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("无照片").font(.caption)
        PhotoCarouselView(filenames: [])

        Text("文件不存在（演示降级路径）").font(.caption)
        PhotoCarouselView(filenames: ["nonexistent-\(UUID().uuidString).jpg"])
    }
    .padding()
}