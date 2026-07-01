import SwiftUI
import PhotosUI
import UIKit

/// 照片选择项
///
/// 使用 UUID 作为 id 避免 `Data` 作为 `ForEach` id 时的 hash 冲突
/// （多张 JPEG 文件头相同，曾导致"删一张删所有"的 bug）。
struct PhotoItem: Identifiable {
    let id = UUID()
    var data: Data
    var existingFilename: String?
}

/// 照片选择区（最多 3 张）
///
/// 空状态提供「拍照」+「从相册选」两个并列按钮；
/// 已选状态下末尾「+」按钮弹出菜单，包含两个入口。
/// 模拟器上点拍照按钮会弹出提示 alert。
struct PhotoPickerSection: View {
    @Binding var items: [PhotoItem]
    private let maxCount = FarewellRecord.maxPhotos

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var cameraUnavailableAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("照片")
                .font(.headline)

            if items.isEmpty {
                emptyActions
            } else {
                filledGrid
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                var newItemsData: [PhotoItem] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newItemsData.append(PhotoItem(data: data))
                    }
                }
                await MainActor.run {
                    items.append(contentsOf: newItemsData)
                    selectedItems = []
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                if items.count < maxCount {
                    let newItem = PhotoItem(data: data)
                    items.append(newItem)
                }
            }
            .ignoresSafeArea()
        }
        .alert("模拟器不可用", isPresented: $cameraUnavailableAlert) {
            Button("好") {}
        } message: {
            Text("请在真机上使用拍照功能。")
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItems,
            maxSelectionCount: maxCount - items.count,
            matching: .images
        )
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
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(items) { item in
                PhotoTile(data: item.data, onRemove: {
                    items.removeAll { $0.id == item.id }
                })
            }
            if items.count < maxCount {
                Menu {
                    Button(action: openCamera) {
                        Label("拍照", systemImage: "camera.fill")
                    }

                    Button(action: { showPhotoPicker = true }) {
                        Label("从相册选", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("添加")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
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
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .black.opacity(0.6))
                .padding(4)
                .onTapGesture { onRemove() }
        }
    }
}

#Preview {
    @Previewable @State var items: [PhotoItem] = []
    return PhotoPickerSection(items: $items)
        .padding()
}