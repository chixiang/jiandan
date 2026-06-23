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
}