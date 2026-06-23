import XCTest
@testable import JianDan

// `Category` 与 Foundation 同名冲突；alias 一下
private typealias FarewellCategory = JianDan.Category

@MainActor
final class StatsCalculatorTests: XCTestCase {
    // MARK: - 辅助

    private func makeRecord(
        name: String = "x",
        category: FarewellCategory = .other,
        farewellDate: Date = .now,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        emotionValue: Int? = nil
    ) -> FarewellRecord {
        let record = FarewellRecord(
            name: name,
            category: category,
            farewellDate: farewellDate,
            method: .donate,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            emotionValue: emotionValue
        )
        return record
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - 空态

    func testEmptyInputReturnsZeroStats() {
        let stats = StatsCalculator.compute(from: [])
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.totalCompanionshipDays, 0)
        XCTAssertEqual(stats.longestCompanionshipDays, 0)
        XCTAssertEqual(stats.thisMonthCount, 0)
        XCTAssertEqual(stats.totalPurchasePrice, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertNil(stats.averageEmotion)
        XCTAssertTrue(stats.isEmpty)
    }

    // MARK: - 基础计数

    func testTotalCount() {
        let records = [
            makeRecord(name: "a"),
            makeRecord(name: "b"),
            makeRecord(name: "c"),
        ]
        XCTAssertEqual(StatsCalculator.compute(from: records).totalCount, 3)
    }

    // MARK: - 陪伴天数

    func testCompanionshipDaysSumsAndMax() {
        // 100 天 + 365 天 + 30 天 = 495 总和；max = 365
        let records = [
            makeRecord(
                farewellDate: date(year: 2024, month: 4, day: 10),
                purchaseDate: date(year: 2024, month: 1, day: 1)
            ),
            makeRecord(
                farewellDate: date(year: 2024, month: 1, day: 1),
                purchaseDate: date(year: 2023, month: 1, day: 1)
            ),
            makeRecord(
                farewellDate: date(year: 2024, month: 1, day: 31),
                purchaseDate: date(year: 2024, month: 1, day: 1)
            ),
        ]
        let stats = StatsCalculator.compute(from: records)
        // 容差 ±1 天（跨年计算可能差一天）
        XCTAssertEqual(stats.totalCompanionshipDays, 495, accuracy: 3)
        XCTAssertEqual(stats.longestCompanionshipDays, 365, accuracy: 1)
    }

    func testRecordsWithoutPurchaseDateAreSkippedFromCompanionship() {
        let records = [
            makeRecord(purchaseDate: nil),  // 无购入日期
            makeRecord(
                farewellDate: date(year: 2024, month: 1, day: 11),
                purchaseDate: date(year: 2024, month: 1, day: 1)
            ),
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertEqual(stats.totalCount, 2, "总数不受影响")
        XCTAssertEqual(stats.totalCompanionshipDays, 10, accuracy: 1, "无购入日期的应跳过")
    }

    // MARK: - 本月计数

    func testThisMonthCount() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 1)),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 30)),
            makeRecord(farewellDate: date(year: 2026, month: 5, day: 31)),  // 上月
            makeRecord(farewellDate: date(year: 2026, month: 7, day: 1)),  // 下月
        ]
        let stats = StatsCalculator.compute(from: records, referenceDate: now)
        XCTAssertEqual(stats.thisMonthCount, 2)
    }

    // MARK: - 总价

    func testTotalPurchasePriceSumsAndSkipsNil() {
        let records = [
            makeRecord(purchasePrice: 100),
            makeRecord(purchasePrice: 200.5),
            makeRecord(purchasePrice: nil),  // 跳过
        ]
        XCTAssertEqual(StatsCalculator.compute(from: records).totalPurchasePrice, 300.5, accuracy: 0.01)
    }

    // MARK: - 分类分布

    func testCategoryBreakdownIsSortedByCountDescending() {
        let records = [
            makeRecord(category: FarewellCategory.clothing),
            makeRecord(category: FarewellCategory.clothing),
            makeRecord(category: FarewellCategory.books),
            makeRecord(category: FarewellCategory.electronics),
            makeRecord(category: FarewellCategory.electronics),
            makeRecord(category: FarewellCategory.electronics),
        ]
        let breakdown = StatsCalculator.compute(from: records).categoryBreakdown
        XCTAssertEqual(breakdown.count, 3)
        XCTAssertEqual(breakdown[0].category, .electronics)
        XCTAssertEqual(breakdown[0].count, 3)
        XCTAssertEqual(breakdown[1].category, .clothing)
        XCTAssertEqual(breakdown[2].category, .books)
    }

    func testFarewellStatsEquatable() {
        let a = FarewellStats(
            totalCount: 3,
            totalCompanionshipDays: 10,
            longestCompanionshipDays: 5,
            thisMonthCount: 1,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: FarewellCategory.books, count: 3)],
            averageEmotion: 4.0
        )
        let b = FarewellStats(
            totalCount: 3,
            totalCompanionshipDays: 10,
            longestCompanionshipDays: 5,
            thisMonthCount: 1,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: FarewellCategory.books, count: 3)],
            averageEmotion: 4.0
        )
        XCTAssertEqual(a, b, "FarewellStats 应可比较相等")
    }

    // MARK: - 情感均值

    func testAverageEmotion() {
        let records = [
            makeRecord(emotionValue: 3),
            makeRecord(emotionValue: 5),
            makeRecord(emotionValue: nil),  // 跳过
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertNotNil(stats.averageEmotion)
        XCTAssertEqual(stats.averageEmotion!, 4.0, accuracy: 0.01)
    }

    func testAverageEmotionNilWhenNoEmotionValues() {
        let records = [
            makeRecord(emotionValue: nil),
            makeRecord(emotionValue: nil),
        ]
        XCTAssertNil(StatsCalculator.compute(from: records).averageEmotion)
    }

    // MARK: - 集成

    func testIsEmptyFlag() {
        XCTAssertTrue(StatsCalculator.compute(from: []).isEmpty)
        XCTAssertFalse(StatsCalculator.compute(from: [makeRecord()]).isEmpty)
    }
}