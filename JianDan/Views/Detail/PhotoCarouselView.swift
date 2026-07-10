import SwiftUI

/// 全屏查看器触发项（每次点击生成新 UUID，保证 fullScreenCover 刷新）
private struct ViewerItem: Identifiable {
    let id = UUID()
    let filenames: [String]
    let index: Int
}

/// 多张照片轮播 — 正方形卡片
struct PhotoCarouselView: View {
    let filenames: [String]
    @Environment(\.appTheme) private var theme

    @State private var viewerItem: ViewerItem?

    var body: some View {
        if filenames.isEmpty {
            ZStack {
                Rectangle()
                    .fill(theme.divider.opacity(0.3))
                Image(systemName: "photo")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(theme.secondary)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        } else {
            TabView {
                ForEach(Array(filenames.enumerated()), id: \.offset) { index, filename in
                    if let image = ImageStore.loadImage(filename: filename) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onTapGesture {
                                viewerItem = ViewerItem(filenames: filenames, index: index)
                            }
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(theme.divider.opacity(0.3))
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(.orange)
                                Text("照片已丢失")
                                    .appFont(.caption)
                                    .foregroundStyle(theme.secondary)
                            }
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: filenames.count > 1 ? .always : .never))
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(theme.divider, lineWidth: 0.5)
            )
            .fullScreenCover(item: $viewerItem) { item in
                FullScreenImageViewer(filenames: item.filenames, initialIndex: item.index)
                    .ignoresSafeArea()
            }
        }
    }
}