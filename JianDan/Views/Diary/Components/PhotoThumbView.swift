import SwiftUI

/// 单张照片缩略图（拍立得风格）
struct PhotoThumbView: View {
    let data: Data?
    let category: Category
    var size: CGFloat = 80

    var body: some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 占位：分类图标
                ZStack {
                    Rectangle()
                        .fill(.tertiary.opacity(0.3))
                    Image(systemName: category.icon)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    HStack {
        PhotoThumbView(data: nil, category: .clothing)
        PhotoThumbView(data: Data([0xFF, 0xD8, 0xFF]), category: .books)
    }
}
