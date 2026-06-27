import XCTest
import SwiftData
@testable import JianDan

@MainActor
final class FarewellRecordTests: XCTestCase {
    /// 内存测试容器：每个测试用独立 container 避免污染
    func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([FarewellRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testBasicInit() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(
            name: "一件蓝色羊毛大衣",
            category: .builtin(.clothing),
            method: .donate
        )
        context.insert(record)
        try context.save()

        XCTAssertEqual(record.name, "一件蓝色羊毛大衣")
        XCTAssertEqual(record.category, .builtin(.clothing))
        XCTAssertEqual(record.method, .donate)
        XCTAssertEqual(record.categoryRaw, "衣物")
        XCTAssertEqual(record.methodRaw, "捐赠")
        XCTAssertNotNil(record.id)
        XCTAssertNotNil(record.createdAt)
        XCTAssertNotNil(record.updatedAt)
        XCTAssertTrue(record.photoFilenames.isEmpty)
    }

    func testInitWithPhotos() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let filenames = ["a.jpg", "b.jpg"]
        let record = FarewellRecord(
            name: "台灯",
            category: .builtin(.furniture),
            method: .gift,
            photoFilenames: filenames
        )
        context.insert(record)
        XCTAssertEqual(record.photoFilenames.count, 2)
        XCTAssertEqual(record.photoFilenames, filenames)
    }

    func testCompanionshipDays() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let purchase = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let farewell = Calendar.current.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let record = FarewellRecord(
            name: "旧电脑",
            category: .builtin(.electronics),
            farewellDate: farewell,
            method: .discard
        )
        record.purchaseDate = purchase
        context.insert(record)

        // 三年整 = 1096 或 1095 天（取决于闰年）；测试容差 ±1
        let days = record.companionshipDays
        XCTAssertNotNil(days)
        XCTAssertEqual(days!, 1096, accuracy: 1)
    }

    func testCompanionshipDaysNilWhenNoPurchaseDate() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(
            name: "某物",
            category: .builtin(.other),
            method: .other
        )
        context.insert(record)
        XCTAssertNil(record.companionshipDays)
    }

    func testCategoryRawRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(name: "X", category: .builtin(.books), method: .other)
        context.insert(record)

        // 通过 rawValue 设置 + 读取 category getter
        record.categoryRaw = "电子"
        XCTAssertEqual(record.category, .builtin(.electronics))

        // 通过 categoryID setter 设置（category 改为 get-only）
        record.categoryID = AnyCategory.builtin(.furniture).storageID
        XCTAssertEqual(record.categoryRaw, "家具")
    }

    func testMethodRawRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(name: "X", category: .builtin(.other), method: .other)
        context.insert(record)

        record.methodRaw = "扔掉"
        XCTAssertEqual(record.method, .discard)

        record.method = .gift
        XCTAssertEqual(record.methodRaw, "送人")
    }

    // MARK: - Precondition tests
    //
    // 真实的 precondition 捕获在零依赖前提下极难做到：
    // - XCTest 本身不拦截 fatalError / precondition
    // - 三方库（pointfreeco/xctest-dynamic-overlay 等）会引入外部依赖
    // - POSIX signal handler 在 Swift 测试中并不可靠
    //
    // 因此 precondition 校验通过以下两点保证：
    // 1. 文档化在 init 中存在的 precondition（见 FarewellRecord.swift）
    // 2. 业务/UI 层在调用前预先校验（下一 Task 引入 Form 校验时）
    //
    // 当前 Task 范围内：跳过 precondition 用例，仅记录文档化意图。
    // 失败示例（DEBUG 下会 crash 测试进程）：
    //   let record = FarewellRecord(name: "", category: .builtin(.other), method: .other)
    //   let record = FarewellRecord(name: String(repeating: "一", count: 51), ...)
    //   let record = FarewellRecord(name: "X", ..., photoFilenames: ["a","b","c","d"])

    // MARK: - 完整 CRUD 流程测试

    func testFullCRUDFlow() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        // Create
        let record = FarewellRecord(
            name: "一套旧书",
            category: .builtin(.books),
            method: .donate,
            photoFilenames: ["test.jpg"]
        )
        record.farewellLetter = "这些书陪我度过了大学时光"
        record.purchasePrice = 120.0
        record.emotionValue = 4
        record.recipientDetail = "学校图书馆"
        context.insert(record)
        try context.save()

        // Read
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.name == "一套旧书" }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        let loaded = fetched[0]
        XCTAssertEqual(loaded.category, .builtin(.books))
        XCTAssertEqual(loaded.method, .donate)
        XCTAssertEqual(loaded.farewellLetter, "这些书陪我度过了大学时光")
        XCTAssertEqual(loaded.purchasePrice, 120.0)
        XCTAssertEqual(loaded.emotionValue, 4)
        XCTAssertEqual(loaded.recipientDetail, "学校图书馆")
        XCTAssertEqual(loaded.photoFilenames.count, 1)
        XCTAssertEqual(loaded.photoFilenames, ["test.jpg"])

        // Update
        loaded.farewellLetter = "更新后的减单一言"
        try context.save()
        XCTAssertEqual(loaded.farewellLetter, "更新后的减单一言")

        // Delete
        context.delete(loaded)
        try context.save()
        let afterDelete = try context.fetch(descriptor)
        XCTAssertTrue(afterDelete.isEmpty)
    }

    // MARK: - 时间字段

    func testCreatedAtEqualsUpdatedAtInitially() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(name: "X", category: .builtin(.other), method: .other)
        context.insert(record)
        // init 时两者都是 .now，但可能相差数微秒，用 ±0.1s 容差
        let diff = abs(record.createdAt.timeIntervalSince(record.updatedAt))
        XCTAssertLessThan(diff, 0.1, "init 时 createdAt 与 updatedAt 应几乎相等 (差 \(diff)s)")
    }

    func testUpdatedAtCanBeChanged() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let record = FarewellRecord(name: "X", category: .builtin(.other), method: .other)
        context.insert(record)
        let originalUpdatedAt = record.updatedAt
        Thread.sleep(forTimeInterval: 0.01)
        record.updatedAt = .now
        XCTAssertGreaterThan(record.updatedAt, originalUpdatedAt)
    }

    // MARK: - SwiftData fetch / predicate

    func testFetchSortedByFarewellDateDesc() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let older = FarewellRecord(
            name: "older",
            category: .builtin(.other),
            farewellDate: Date(timeIntervalSince1970: 1_700_000_000),
            method: .donate
        )
        let newer = FarewellRecord(
            name: "newer",
            category: .builtin(.other),
            farewellDate: Date(timeIntervalSince1970: 1_800_000_000),
            method: .donate
        )
        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<FarewellRecord>(
            sortBy: [SortDescriptor(\.farewellDate, order: .reverse)]
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched.first?.name, "newer", "倒序：第一条应是 newer")
    }

    func testFetchByCategoryRawPredicate() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let booksRecord = FarewellRecord(
            name: "book1",
            category: .builtin(.books),
            method: .donate
        )
        let clothingRecord = FarewellRecord(
            name: "shirt1",
            category: .builtin(.clothing),
            method: .donate
        )
        context.insert(booksRecord)
        context.insert(clothingRecord)
        try context.save()

        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.categoryRaw == "书籍" }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "book1")
    }

    func testFetchByFarewellDateRangePredicate() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let inRange = FarewellRecord(
            name: "in",
            category: .builtin(.other),
            farewellDate: Date(timeIntervalSince1970: 1_750_000_000),
            method: .donate
        )
        let outOfRange = FarewellRecord(
            name: "out",
            category: .builtin(.other),
            farewellDate: Date(timeIntervalSince1970: 1_600_000_000),
            method: .donate
        )
        context.insert(inRange)
        context.insert(outOfRange)
        try context.save()

        let lower = Date(timeIntervalSince1970: 1_700_000_000)
        let upper = Date(timeIntervalSince1970: 1_800_000_000)
        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.farewellDate >= lower && $0.farewellDate <= upper }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "in")
    }

    func testFetchEmptyContainerReturnsEmptyArray() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<FarewellRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testFetchWithLimit() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        for i in 0..<5 {
            context.insert(FarewellRecord(
                name: "r\(i)",
                category: .builtin(.other),
                method: .donate
            ))
        }
        try context.save()

        var descriptor = FetchDescriptor<FarewellRecord>()
        descriptor.fetchLimit = 3
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 3)
    }

    // MARK: - 字段默认值

    func testDefaultFarewellDateIsNow() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let before = Date()
        let record = FarewellRecord(name: "X", category: .builtin(.other), method: .other)
        let after = Date()
        context.insert(record)
        XCTAssertGreaterThanOrEqual(record.farewellDate, before)
        XCTAssertLessThanOrEqual(record.farewellDate, after)
    }
}
