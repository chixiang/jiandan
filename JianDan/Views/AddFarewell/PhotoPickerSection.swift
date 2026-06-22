import SwiftUI
import PhotosUI

/// 照片选择区（最多 3 张）
struct PhotoPickerSection: View {
    @Binding var photos: [Data]
    private let maxCount = FarewellRecord.maxPhotos

    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("照片")
                .font(.headline)

            if photos.isEmpty {
                // 初始状态：单一 + 按钮
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: maxCount,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "camera")
                        Text("添加照片")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                // 已选照片：网格 + 添加更多
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                        PhotoTile(data: data, onRemove: {
                            photos.remove(at: index)
                        })
                    }
                    if photos.count < maxCount {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: maxCount - photos.count,
                            matching: .images
                        ) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("添加")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                var newData: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newData.append(data)
                    }
                }
                await MainActor.run {
                    photos.append(contentsOf: newData)
                    selectedItems = []
                }
            }
        }
    }
}

private struct PhotoTile: View {
    let data: Data
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(4)
        }
    }
}

#Preview {
    @Previewable @State var photos: [Data] = []
    return PhotoPickerSection(photos: $photos)
        .padding()
}