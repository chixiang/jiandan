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
    var isLoading = false
}

/// 照片选择区（最多 3 张）
///
/// 空状态提供「拍照」+「相册」两个并列按钮；
/// 已选状态下末尾「+」按钮弹出菜单，包含两个入口。
/// 模拟器上点拍照按钮会弹出提示 alert。
struct PhotoPickerSection: View {
    @Binding var items: [PhotoItem]
    @Environment(\.appTheme) private var theme
    private let maxCount = FarewellRecord.maxPhotos

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var cameraUnavailableAlert = false

    @State private var cropQueue: [UIImage] = []
    @State private var currentCropImage: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text("照片")
                .appFont(.sectionTitle)

            if items.isEmpty {
                emptyActions
            } else {
                filledGrid
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                var images: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                await MainActor.run {
                    cropQueue = images
                    selectedItems = []
                    processNextCrop()
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            SquareCameraView { data in
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
        .sheet(isPresented: .init(
            get: { currentCropImage != nil },
            set: { if !$0 { currentCropImage = nil; processNextCrop() } }
        )) {
            if let image = currentCropImage {
                SquareCropView(
                    image: image,
                    onCrop: { data in
                        items.append(PhotoItem(data: data))
                        currentCropImage = nil
                        processNextCrop()
                    },
                    onCancel: {
                        currentCropImage = nil
                        processNextCrop()
                    }
                )
            }
        }
    }

    // MARK: - Actions

    private func processNextCrop() {
        guard !cropQueue.isEmpty else { currentCropImage = nil; return }
        currentCropImage = cropQueue.removeFirst()
    }

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            cameraUnavailableAlert = true
        }
    }

    // MARK: - 空状态

    private var emptyActions: some View {
        HStack(spacing: .sm) {
            Button(action: openCamera) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("拍照")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .xl)
                .background(theme.divider.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxCount,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("相册")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .xl)
                .background(theme.divider.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 已选状态

    private var filledGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: .xs),
            GridItem(.flexible(), spacing: .xs),
            GridItem(.flexible())
        ], spacing: .xs) {
            ForEach(items) { item in
                PhotoTile(data: item.data, isLoading: item.isLoading, onRemove: {
                    items.removeAll { $0.id == item.id }
                })
            }
            if items.count < maxCount {
                Menu {
                    Button(action: openCamera) {
                        Label("拍照", systemImage: "camera.fill")
                    }

                    Button(action: { showPhotoPicker = true }) {
                        Label("相册", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .appFont(.title)
                        Text("添加")
                            .appFont(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(theme.divider.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                }
            }
        }
    }
}

private struct PhotoTile: View {
    let data: Data
    let isLoading: Bool
    let onRemove: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isLoading {
                    Color.gray.opacity(0.15)
                        .shimmer()
                } else if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if !isLoading {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .padding(4)
                        .onTapGesture { onRemove() }
                }
            }
    }
}

#Preview {
    @Previewable @State var items: [PhotoItem] = []
    return PhotoPickerSection(items: $items)
        .padding()
}