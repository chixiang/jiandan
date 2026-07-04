import SwiftUI

/// 单张照片缩略图（拍立得风格）
/// 通过 ImageStore 从沙盒加载图片
struct PhotoThumbView: View {
    @Environment(\.appTheme) private var theme
    let filename: String?
    let category: AnyCategory
    var size: CGFloat = 80

    var body: some View {
        Group {
            if let filename, let uiImage = ImageStore.loadImage(filename: filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 占位：分类图标
                ZStack {
                    Rectangle()
                        .fill(theme.divider.opacity(0.3))
                    Image(systemName: category.iconName)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(theme.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    HStack {
        PhotoThumbView(filename: nil, category: .builtin(.clothing))
        PhotoThumbView(filename: "missing.jpg", category: .builtin(.books))
    }
}