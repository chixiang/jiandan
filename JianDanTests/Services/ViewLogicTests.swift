import XCTest
import SwiftData
@testable import JianDan

/// 视图逻辑层的单元测试 —— 覆盖 `Services/AddFarewellValidator`、`Services/EditFarewellSaver`、
/// `Services/RecordDeleter` 三个从视图抽出的纯函数 helper。
@MainActor
final class ViewLogicTests: XCTestCase {

    // MARK: - 容器工厂

    private func makeContainer() -> ModelContainer {
        let schema = Schema([FarewellRecord.self, UserCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }

    private func makeRecord(
        name: String = "测试物品",
        category: JianDan.Category = .other,
        farewellLetter: String? = nil,
        recipientDetail: String? = nil
    ) -> FarewellRecord {
        let r = FarewellRecord(
            name: name,
            category: .builtin(category),
            method: .donate,
            recipientDetail: recipientDetail,
            farewellLetter: farewellLetter
        )
        return r
    }

    // MARK: - AddFarewellValidator.canSave

    func testCanSaveEmptyNameReturnsFalse() {
        XCTAssertFalse(AddFarewellValidator.canSave(name: ""))
    }

    func testCanSaveWhitespaceOnlyNameReturnsFalse() {
        XCTAssertFalse(AddFarewellValidator.canSave(name: "    "))
        XCTAssertFalse(AddFarewellValidator.canSave(name: "\n\t  \n"))
    }

    func testCanSaveValidNameReturnsTrue() {
        XCTAssertTrue(AddFarewellValidator.canSave(name: "一件蓝色羊毛大衣"))
    }

    func testCanSaveNameWithLeadingTrailingSpaceIsValid() {
        // "  羊毛大衣  " trim 后有效
        XCTAssertTrue(AddFarewellValidator.canSave(name: "  羊毛大衣  "))
    }

    func testCanSaveAtMaxLengthReturnsTrue() {
        let name = String(repeating: "一", count: FarewellRecord.nameMaxLength)
        XCTAssertTrue(AddFarewellValidator.canSave(name: name))
    }

    func testCanSaveBeyondMaxLengthReturnsFalse() {
        // 51 字超过 50 上限
        let longName = String(repeating: "一", count: FarewellRecord.nameMaxLength + 1)
        XCTAssertFalse(AddFarewellValidator.canSave(name: longName))
    }

    // MARK: - EditFarewellSaver.truncateName

    func testTruncateNameNoOpWhenWithinLimit() {
        let record = makeRecord(name: "正常长度")
        EditFarewellSaver.truncateName(record)
        XCTAssertEqual(record.name, "正常长度")
    }

    func testTruncateNameShortensOversizedValue() {
        let record = makeRecord(name: "初始名")
        // 直接修改字段（init 阶段已通过 precondition；运行时 setter 不再校验）
        record.name = String(repeating: "一", count: 80)
        EditFarewellSaver.truncateName(record)
        XCTAssertEqual(record.name.count, FarewellRecord.nameMaxLength)
    }

    func testTruncateNameAtBoundaryIsIdempotent() {
        let exactName = String(repeating: "一", count: FarewellRecord.nameMaxLength)
        let record = makeRecord(name: exactName)
        EditFarewellSaver.truncateName(record)
        EditFarewellSaver.truncateName(record)  // 第二次
        XCTAssertEqual(record.name.count, FarewellRecord.nameMaxLength)
    }

    // MARK: - EditFarewellSaver.truncateFarewellLetter

    func testTruncateFarewellLetterNoOpWhenNil() {
        let record = makeRecord(farewellLetter: nil)
        EditFarewellSaver.truncateFarewellLetter(record)
        XCTAssertNil(record.farewellLetter)
    }

    func testTruncateFarewellLetterNoOpWhenWithinLimit() {
        let record = makeRecord(farewellLetter: "短一些的信")
        EditFarewellSaver.truncateFarewellLetter(record)
        XCTAssertEqual(record.farewellLetter, "短一些的信")
    }

    func testTruncateFarewellLetterShortensOversizedValue() {
        let record = makeRecord(farewellLetter: "初值")
        // 直接修改（绕开 init 的 precondition）
        record.farewellLetter = String(repeating: "字", count: 1000)
        EditFarewellSaver.truncateFarewellLetter(record)
        XCTAssertEqual(record.farewellLetter?.count, FarewellRecord.farewellLetterMaxLength)
    }

    // MARK: - EditFarewellSaver.truncateRecipientDetail

    func testTruncateRecipientDetailShortensOversizedValue() {
        let record = makeRecord(recipientDetail: "初始详情")
        // 直接修改（绕开 init 的 precondition）
        record.recipientDetail = String(repeating: "字", count: 500)
        EditFarewellSaver.truncateRecipientDetail(record)
        XCTAssertEqual(record.recipientDetail?.count, FarewellRecord.recipientDetailMaxLength)
    }

    func testTruncateRecipientDetailNoOpWhenNil() {
        let record = makeRecord(recipientDetail: nil)
        EditFarewellSaver.truncateRecipientDetail(record)
        XCTAssertNil(record.recipientDetail)
    }

    // MARK: - EditFarewellSaver.save

    func testSaveUpdatesUpdatedAtTimestamp() throws {
        let container = makeContainer()
        let context = ModelContext(container)
        let record = makeRecord()
        context.insert(record)
        try context.save()

        let originalUpdatedAt = record.updatedAt

        // 等一小段时间确保时间戳不同
        Thread.sleep(forTimeInterval: 0.01)

        try EditFarewellSaver.save(record, in: context)
        XCTAssertGreaterThan(record.updatedAt, originalUpdatedAt)
    }

    func testSavePersistsChanges() throws {
        let container = makeContainer()
        let context = ModelContext(container)
        let record = makeRecord(name: "改名前")
        context.insert(record)
        try context.save()

        record.name = "改名后"
        try EditFarewellSaver.save(record, in: context)

        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.name == "改名后" }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "改名后")
    }

    // MARK: - RecordDeleter.delete

    func testRecordDeleterRemovesRecordFromContext() throws {
        let container = makeContainer()
        let context = ModelContext(container)
        let record = makeRecord(name: "待删除")
        context.insert(record)
        try context.save()

        let id = record.id
        try RecordDeleter.delete(record, in: context)

        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.id == id }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertTrue(fetched.isEmpty, "删除后该 id 不应再可查询到")
    }

    func testRecordDeleterRemovesAssociatedImages() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        // 真实图片存盘
        let filename = try ImageStore.save(Self.makeTestImageData())
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: ImageStore.directoryURL.appendingPathComponent(filename).path
        ))

        let record = makeRecord()
        record.photoFilenames = [filename]
        context.insert(record)
        try context.save()

        try RecordDeleter.delete(record, in: context)

        XCTAssertFalse(FileManager.default.fileExists(
            atPath: ImageStore.directoryURL.appendingPathComponent(filename).path
        ), "图片文件应被清理"
        )
    }

    func testRecordDeleterDoesNotThrowOnMissingImages() throws {
        let container = makeContainer()
        let context = ModelContext(container)
        let record = makeRecord()
        record.photoFilenames = ["nonexistent-\(UUID().uuidString).jpg"]
        context.insert(record)
        try context.save()

        // 删除应该成功 —— 图片清理失败被吞掉
        XCTAssertNoThrow(try RecordDeleter.delete(record, in: context))
    }

    func testRecordDeleterRemovesAllPhotosWhenMultipleExist() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        let f1 = try ImageStore.save(Self.makeTestImageData())
        let f2 = try ImageStore.save(Self.makeTestImageData())

        let record = makeRecord()
        record.photoFilenames = [f1, f2]
        context.insert(record)
        try context.save()

        try RecordDeleter.delete(record, in: context)

        XCTAssertFalse(FileManager.default.fileExists(
            atPath: ImageStore.directoryURL.appendingPathComponent(f1).path
        ))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: ImageStore.directoryURL.appendingPathComponent(f2).path
        ))
    }

    override func tearDown() {
        super.tearDown()
        // 清理测试期间创建的图片
        let dir = ImageStore.directoryURL
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "jpg" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // 构造一张 100x100 红色 PNG
    private static func makeTestImageData() -> Data {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), true, 1.0)
        defer { UIGraphicsEndImageContext() }
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.pngData() ?? Data()
    }
}