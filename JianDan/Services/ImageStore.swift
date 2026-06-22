import Foundation
import UIKit

/// 图片存储服务：照片单独存于沙盒，SwiftData 模型只存文件名
/// - 设计原则：每张照片压缩到最长边 1920px + JPEG 0.85（肉眼无损，省 60-80% 空间）
/// - 命名规则：UUID + .jpg
/// - 路径：`Documents/images/<UUID>.jpg`
final class ImageStore {
    private static let directoryName = "images"
    private static let maxDimension: CGFloat = 1920
    private static let compressionQuality: CGFloat = 0.85

    /// 图片目录 URL（自动创建）
    static var directoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 保存图片：压缩 → 写入沙盒 → 返回文件名
    /// - Parameter data: 原始图片数据（任意格式：HEIC / JPEG / PNG）
    /// - Returns: 文件名（UUID + .jpg）
    static func save(_ data: Data) throws -> String {
        guard let image = UIImage(data: data) else {
            throw ImageStoreError.imageDecodingFailed
        }

        let resized = resize(image, maxDimension: maxDimension)
        guard let jpegData = resized.jpegData(compressionQuality: compressionQuality) else {
            throw ImageStoreError.writeFailed(
                underlying: NSError(domain: "ImageStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "JPEG 编码失败"])
            )
        }

        let filename = "\(UUID().uuidString).jpg"
        let url = directoryURL.appendingPathComponent(filename)

        do {
            try jpegData.write(to: url, options: .atomic)
            return filename
        } catch {
            throw ImageStoreError.writeFailed(underlying: error)
        }
    }

    /// 删除单张图片（不存在时静默忽略）
    static func delete(filename: String) throws {
        let url = directoryURL.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw ImageStoreError.deleteFailed(underlying: error)
        }
    }

    /// 批量删除
    static func delete(filenames: [String]) throws {
        for filename in filenames {
            try delete(filename: filename)
        }
    }

    /// 加载 Data
    static func load(filename: String) -> Data? {
        let url = directoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    /// 加载 UIImage（便捷）
    static func loadImage(filename: String) -> UIImage? {
        guard let data = load(filename: filename) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Private

    /// 缩放图片至最长边 ≤ maxDimension
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum ImageStoreError: Error, LocalizedError, Equatable {
    case imageDecodingFailed
    case writeFailed(underlying: Error)
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .imageDecodingFailed:
            return "图片解码失败"
        case .writeFailed(let error):
            return "图片写入失败：\(error.localizedDescription)"
        case .deleteFailed(let error):
            return "图片删除失败：\(error.localizedDescription)"
        }
    }

    // 实现 Equatable 时跳过关联值比较（NSError 不易 Equatable）
    static func == (lhs: ImageStoreError, rhs: ImageStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.imageDecodingFailed, .imageDecodingFailed):
            return true
        case (.writeFailed, .writeFailed):
            return true
        case (.deleteFailed, .deleteFailed):
            return true
        default:
            return false
        }
    }
}