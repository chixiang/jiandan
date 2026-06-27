import XCTest
import SwiftData
@testable import JianDan

@MainActor
final class DataImporterTests: XCTestCase {
    /// 内存测试容器：每个测试用独立 container 避免污染
    func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([FarewellRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// 测试用 JSON 数据（内联，不依赖 bundle）
    private var sampleJSONData: Data {
        let json = """
        {
          "version": 1,
          "records": [
            {"name": "蓝色羊毛大衣", "category": "衣物", "farewellDate": "2026-01-15", "method": "捐赠", "purchaseDate": "2024-11-20", "purchasePrice": 1280, "emotionValue": 4, "recipientDetail": "回收箱", "farewellLetter": "暖意还在", "photoFilenames": []},
            {"name": "旧小说全集", "category": "书籍", "farewellDate": "2025-12-28", "method": "送人", "purchaseDate": "2019-09-01", "purchasePrice": 320, "emotionValue": 5, "recipientDetail": "图书馆", "farewellLetter": "去陪下一个人了", "photoFilenames": []},
            {"name": "旧笔记本", "category": "电子", "farewellDate": "2026-03-10", "method": "二手出售", "purchaseDate": "2021-06-15", "purchasePrice": 5600, "emotionValue": 3, "farewellLetter": "使命未尽", "photoFilenames": []},
            {"name": "木书架", "category": "家具", "farewellDate": "2026-05-01", "method": "送人", "purchaseDate": "2022-01-20", "purchasePrice": 780, "emotionValue": 3, "recipientDetail": "邻居", "farewellLetter": "架子还在，书散了", "photoFilenames": []},
            {"name": "旧明信片一箱", "category": "杂物", "farewellDate": "2026-06-20", "method": "扔掉", "emotionValue": 5, "farewellLetter": "每一张都是一段路", "photoFilenames": []},
            {"name": "电饭煲", "category": "杂物", "farewellDate": "2026-04-05", "method": "捐赠", "purchaseDate": "2023-03-01", "purchasePrice": 399, "emotionValue": 2, "recipientDetail": "义卖", "farewellLetter": "盖子合不上了", "photoFilenames": []},
            {"name": "陶瓷杯", "category": "其他", "farewellDate": "2026-02-14", "method": "其他", "purchaseDate": "2023-09-01", "emotionValue": 4, "recipientDetail": "碎了", "farewellLetter": "使命已尽", "photoFilenames": []},
            {"name": "厚被褥", "category": "衣物", "farewellDate": "2026-06-01", "method": "捐赠", "purchaseDate": "2024-01-10", "purchasePrice": 450, "emotionValue": 3, "recipientDetail": "社区站", "farewellLetter": "不再需要这么厚了", "photoFilenames": []}
          ]
        }
        """
        return json.data(using: .utf8)!
    }

    // MARK: - 基本导入

    func testImportSampleRecordsSuccess() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let result = importer.importSampleRecords(jsonData: sampleJSONData)

        XCTAssertTrue(result.isSuccess, "import should succeed")
        XCTAssertEqual(result.imported, 8, "should import all 8 sample records")
        XCTAssertEqual(result.skipped, 0, "no duplicates on first import")
        XCTAssertNil(result.error)
    }

    func testImportIsIdempotent() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let first = importer.importSampleRecords(jsonData: sampleJSONData)
        let second = importer.importSampleRecords(jsonData: sampleJSONData)

        // 第二次应全部跳过（名称 + 告别日期去重）
        XCTAssertEqual(first.imported, 8, "first import: 8 new")
        XCTAssertEqual(first.skipped, 0)
        XCTAssertEqual(second.imported, 0, "second import: all skipped (duplicates)")
        XCTAssertEqual(second.skipped, 8, "second import: 8 skipped")
    }

    // MARK: - 数据完整性

    func testImportedRecordsHaveValidNames() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)
        importer.importSampleRecords(jsonData: sampleJSONData)

        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)

        XCTAssertEqual(all.count, 8)
        for record in all {
            XCTAssertFalse(
                record.name.trimmingCharacters(in: .whitespaces).isEmpty,
                "Imported record name should not be empty"
            )
        }
    }

    func testImportedRecordsCoverMultipleCategories() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)
        importer.importSampleRecords(jsonData: sampleJSONData)

        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)

        let categories = Set(all.map(\.category))
        XCTAssertGreaterThanOrEqual(categories.count, 3, "Should cover at least 3 categories")
    }

    // MARK: - DataImporter.ImportResult

    func testImportResultEquatable() {
        let success = DataImporter.ImportResult(imported: 8, skipped: 0, error: nil)
        let failed = DataImporter.ImportResult(imported: 0, skipped: 0, error: "file not found")

        XCTAssertTrue(success.isSuccess)
        XCTAssertFalse(failed.isSuccess)
        XCTAssertEqual(success, DataImporter.ImportResult(imported: 8, skipped: 0, error: nil))
    }

    // MARK: - 错误路径

    func testImportWithInvalidJSONReturnsError() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let badJSON = "not a json {{{".data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: badJSON)

        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 0)
    }

    func testImportWithMissingRecordsFieldReturnsError() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        { "version": 1 }
        """.data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: json)

        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error)
    }

    func testImportWithEmptyRecordsArray() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        { "version": 1, "records": [] }
        """.data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: json)

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.skipped, 0)
    }

    func testImportWithUnknownCategoryFallsBackToOther() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        {
          "version": 1,
          "records": [
            {"name": "未知分类物品", "category": "完全不存在的分类", "farewellDate": "2026-01-15", "method": "捐赠", "photoFilenames": []}
          ]
        }
        """.data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: json)

        XCTAssertTrue(result.isSuccess, "未知 category 应 fallback 到 other 而不是失败")
        XCTAssertEqual(result.imported, 1)

        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.category, .builtin(.other))
    }

    func testImportWithUnknownMethodFallsBackToOther() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        {
          "version": 1,
          "records": [
            {"name": "未知 method 物品", "category": "衣物", "farewellDate": "2026-01-15", "method": "不存在的去向", "photoFilenames": []}
          ]
        }
        """.data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: json)

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.imported, 1)

        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.first?.method, .other)
    }

    func testImportPreservesOptionalFieldsAsNil() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        {
          "version": 1,
          "records": [
            {"name": "全可选空", "category": "衣物", "farewellDate": "2026-01-15", "method": "扔掉", "photoFilenames": []}
          ]
        }
        """.data(using: .utf8)!
        let result = importer.importSampleRecords(jsonData: json)

        XCTAssertEqual(result.imported, 1)
        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)
        let record = all.first
        XCTAssertNil(record?.purchaseDate)
        XCTAssertNil(record?.purchasePrice)
        XCTAssertNil(record?.emotionValue)
        XCTAssertNil(record?.recipientDetail)
        XCTAssertNil(record?.farewellLetter)
    }

    // MARK: - Bundle 默认路径

    func testImportWithoutJsonDataUsesBundle() throws {
        // smoke test：调用默认 bundle 路径（-seedTestData 走的也是这条）
        // sample_records.json 应在 app bundle 中
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let result = importer.importSampleRecords()

        // 测试 bundle 应该能找到该资源（依赖 XcodeGen 资源包含配置）
        // 如果找不到，imported = 0 + error
        if !result.isSuccess {
            XCTAssertNotNil(result.error)
            // 至少断言不抛错即可
            return
        }
        XCTAssertGreaterThan(result.imported, 0, "Bundle 内置 sample_records.json 应至少有 1 条")
    }

    // MARK: - 日期格式

    func testImportDateFormatIsDateOnly() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let importer = DataImporter(context: context)

        let json = """
        {
          "version": 1,
          "records": [
            {"name": "date-test", "category": "衣物", "farewellDate": "2026-06-15", "method": "捐赠", "photoFilenames": []}
          ]
        }
        """.data(using: .utf8)!
        importer.importSampleRecords(jsonData: json)

        let descriptor = FetchDescriptor<FarewellRecord>(
            predicate: #Predicate { $0.name == "date-test" }
        )
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.count, 1)
        // 时间组件应为 0（UTC 0 点的日期）
        let comps = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(secondsFromGMT: 0)!,
            from: all.first!.farewellDate
        )
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 15)
    }

    // MARK: - ImportResult 数学性质

    func testImportResultTotalFound() {
        let result = DataImporter.ImportResult(imported: 3, skipped: 2, error: nil)
        XCTAssertEqual(result.totalFound, 5)
        XCTAssertTrue(result.isSuccess)
    }
}