import XCTest
import UIKit
@testable import JianDan

final class ImageStoreTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // 清理测试期间在沙盒创建的所有 .jpg 文件
        // 注意：生产数据不会被此测试影响，因为此测试在 XCTest 沙盒中运行
        let dir = ImageStore.directoryURL
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "jpg" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// 构造测试图片 Data（100x100 红色 PNG）
    private func makeTestImageData(size: CGSize = CGSize(width: 100, height: 100)) -> Data {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.pngData() ?? Data()
    }

    func testSaveReturnsValidFilename() throws {
        let data = makeTestImageData()
        let filename = try ImageStore.save(data)
        XCTAssertTrue(filename.hasSuffix(".jpg"), "文件名应以 .jpg 结尾")
        XCTAssertTrue(filename.contains("-"), "UUID 应包含连字符")

        // 验证文件确实写入沙盒
        let url = ImageStore.directoryURL.appendingPathComponent(filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "文件应已写入沙盒")
    }

    func testLoadReturnsData() throws {
        let data = makeTestImageData()
        let filename = try ImageStore.save(data)
        let loaded = ImageStore.load(filename: filename)
        XCTAssertNotNil(loaded, "应能加载刚保存的图片")
        XCTAssertGreaterThan(loaded?.count ?? 0, 0, "加载的数据应非空")
    }

    func testLoadImageReturnsUIImage() throws {
        let data = makeTestImageData()
        let filename = try ImageStore.save(data)
        let image = ImageStore.loadImage(filename: filename)
        XCTAssertNotNil(image, "应能解码为 UIImage")
        // 原始 100x100 图片可能因 JPEG 压缩尺寸略变，这里只验证存在
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }

    func testDeleteRemovesFile() throws {
        let data = makeTestImageData()
        let filename = try ImageStore.save(data)

        try ImageStore.delete(filename: filename)

        let url = ImageStore.directoryURL.appendingPathComponent(filename)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "删除后文件应不存在")
    }

    func testDeleteNonExistentFileIsSafe() throws {
        let phantom = "nonexistent-\(UUID().uuidString).jpg"
        XCTAssertNoThrow(try ImageStore.delete(filename: phantom), "删除不存在的文件应静默忽略")
    }

    func testDeleteMultipleFiles() throws {
        let data = makeTestImageData()
        let f1 = try ImageStore.save(data)
        let f2 = try ImageStore.save(data)

        try ImageStore.delete(filenames: [f1, f2])

        XCTAssertFalse(FileManager.default.fileExists(atPath: ImageStore.directoryURL.appendingPathComponent(f1).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: ImageStore.directoryURL.appendingPathComponent(f2).path))
    }

    func testSaveInvalidDataThrows() {
        let invalid = Data([0x00, 0x01, 0x02])
        XCTAssertThrowsError(try ImageStore.save(invalid)) { error in
            XCTAssertEqual(error as? ImageStoreError, .imageDecodingFailed, "无效数据应抛 .imageDecodingFailed")
        }
    }

    func testLargeImageIsResizedDown() throws {
        // 构造一张 4000x3000 大图（足够大触发缩放）
        let largeData = makeTestImageData(size: CGSize(width: 4000, height: 3000))

        let filename = try ImageStore.save(largeData)
        let loaded = ImageStore.load(filename: filename)!
        let image = UIImage(data: loaded)!

        // 最长边应 ≤ 1920（缩放后）
        let longest = max(image.size.width, image.size.height)
        XCTAssertLessThanOrEqual(longest, 1920.0, "大图应被缩放至最长边 ≤ 1920px")

        // 同时验证 JPEG 压缩：JPEG 0.85 比原始 PNG 小
        XCTAssertLessThan(loaded.count, largeData.count, "压缩后应小于原始 PNG")
    }

    func testDirectoryURLAutoCreatesDirectory() {
        // 多次访问 directoryURL 不应报错
        let url1 = ImageStore.directoryURL
        let url2 = ImageStore.directoryURL
        XCTAssertEqual(url1, url2, "多次访问应返回相同 URL")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path), "目录应已创建")
    }
}