import SwiftUI
import PhotosUI
import UIKit

/// 照片选择区（最多 3 张）
///
/// 空状态提供「拍照」+「从相册选」两个并列按钮；
/// 已选状态下末尾「+」按钮弹出菜单，包含两个入口。
/// 模拟器上点拍照按钮会弹出提示 alert。
struct PhotoPickerSection: View {
    @Binding var photos: [Data]
    private let maxCount = FarewellRecord.maxPhotos

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var cameraUnavailableAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("照片")
                .font(.headline)

            if photos.isEmpty {
                emptyActions
            } else {
                filledGrid
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                if photos.count < maxCount {
                    photos.append(data)
                }
            }
            .ignoresSafeArea()
        }
        .alert("模拟器不可用", isPresented: $cameraUnavailableAlert) {
            Button("好") {}
        } message: {
            Text("请在真机上使用拍照功能。")
        }
    }

    // MARK: - Actions

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            cameraUnavailableAlert = true
        }
    }

    // MARK: - 空状态

    private var emptyActions: some View {
        HStack(spacing: 12) {
            Button(action: openCamera) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("拍照")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxCount,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("从相册选")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 已选状态

    private var filledGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                PhotoTile(data: data, onRemove: {
                    photos.remove(at: index)
                })
            }
            if photos.count < maxCount {
                Menu {
                    Button(action: openCamera) {
                        Label("拍照", systemImage: "camera.fill")
                    }

                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxCount - photos.count,
                        matching: .images
                    ) {
                        Label("从相册选", systemImage: "photo.on.rectangle")
                    }
                } label: {
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