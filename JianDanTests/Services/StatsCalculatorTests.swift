import XCTest
import SwiftData
@testable import JianDan

private typealias FarewellCategory = JianDan.Category

@MainActor
final class StatsCalculatorTests: XCTestCase {

    private func makeRecord(
        name: String = "x",
        category: FarewellCategory = .other,
        farewellDate: Date = .now,
        method: FarewellMethod = .donate,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        emotionValue: Int? = nil
    ) -> FarewellRecord {
        FarewellRecord(
            name: name,
            category: .builtin(category),
            farewellDate: farewellDate,
            method: method,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            emotionValue: emotionValue
        )
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
        XCTAssertNil(stats.averageCompanionshipDays)
        XCTAssertEqual(stats.longestCompanionshipDays, 0)
        XCTAssertEqual(stats.totalPurchasePrice, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertTrue(stats.categoryPriceBreakdown.isEmpty)
        XCTAssertTrue(stats.methodBreakdown.isEmpty)
        XCTAssertEqual(stats.emotionBreakdown.count, 3)
        XCTAssertTrue(stats.emotionBreakdown.allSatisfy { $0.count == 0 })
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

    func testCompanionshipDaysAverageAndMax() {
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
        XCTAssertEqual(stats.averageCompanionshipDays!, 165)
        XCTAssertEqual(stats.longestCompanionshipDays, 365, accuracy: 1)
    }

    func testRecordsWithoutPurchaseDateAreSkippedFromCompanionship() {
        let records = [
            makeRecord(purchaseDate: nil),
            makeRecord(
                farewellDate: date(year: 2024, month: 1, day: 11),
                purchaseDate: date(year: 2024, month: 1, day: 1)
            ),
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertEqual(stats.totalCount, 2, "总数不受影响")
        XCTAssertEqual(stats.averageCompanionshipDays!, 10, "无购入日期的应跳过")
    }

    // MARK: - 总价

    func testTotalPurchasePriceSumsAndSkipsNil() {
        let records = [
            makeRecord(purchasePrice: 100),
            makeRecord(purchasePrice: 200.5),
            makeRecord(purchasePrice: nil),
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
        XCTAssertEqual(breakdown[0].category, .builtin(.electronics))
        XCTAssertEqual(breakdown[0].count, 3)
        XCTAssertEqual(breakdown[1].category, .builtin(.clothing))
        XCTAssertEqual(breakdown[2].category, .builtin(.books))
    }

    // MARK: - 分类总价

    func testCategoryPriceBreakdownIsSortedByPriceDescending() {
        let records = [
            makeRecord(category: FarewellCategory.clothing, purchasePrice: 500),
            makeRecord(category: FarewellCategory.clothing, purchasePrice: 300),
            makeRecord(category: FarewellCategory.books, purchasePrice: 100),
            makeRecord(category: FarewellCategory.electronics, purchasePrice: 1200),
        ]
        let breakdown = StatsCalculator.compute(from: records).categoryPriceBreakdown
        XCTAssertEqual(breakdown.count, 3)
        XCTAssertEqual(breakdown[0].category, .builtin(.electronics))
        XCTAssertEqual(breakdown[0].totalPrice, 1200)
        XCTAssertEqual(breakdown[1].category, .builtin(.clothing))
        XCTAssertEqual(breakdown[1].totalPrice, 800)
        XCTAssertEqual(breakdown[2].category, .builtin(.books))
        XCTAssertEqual(breakdown[2].totalPrice, 100)
    }

    func testCategoryPriceSkipsNilPrices() {
        let records = [
            makeRecord(category: FarewellCategory.clothing, purchasePrice: nil),
            makeRecord(category: FarewellCategory.clothing, purchasePrice: nil),
        ]
        XCTAssertTrue(StatsCalculator.compute(from: records).categoryPriceBreakdown.isEmpty)
    }

    // MARK: - 去向分布

    func testMethodBreakdownContainsAllUsedMethods() {
        let records = [
            makeRecord(method: .gift),
            makeRecord(method: .gift),
            makeRecord(method: .donate),
        ]
        let breakdown = StatsCalculator.compute(from: records).methodBreakdown
        XCTAssertEqual(breakdown.count, 2)
        XCTAssertEqual(breakdown[0].name, "送人")
        XCTAssertEqual(breakdown[0].count, 2)
        XCTAssertEqual(breakdown[1].name, "捐赠")
        XCTAssertEqual(breakdown[1].count, 1)
    }

    func testMethodBreakdownExcludesUnusedMethods() {
        let records = [
            makeRecord(method: .gift),
        ]
        let breakdown = StatsCalculator.compute(from: records).methodBreakdown
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertEqual(breakdown[0].name, "送人")
    }

    // MARK: - 情感分布

    func testEmotionBreakdownHasThreeValuesSortedByCount() {
        let records = [
            makeRecord(emotionValue: 3),
            makeRecord(emotionValue: 2),
            makeRecord(emotionValue: 2),
        ]
        let breakdown = StatsCalculator.compute(from: records).emotionBreakdown
        XCTAssertEqual(breakdown.count, 3)
        // 按 count 降序：复杂(2) > 不舍(1) > 平静(0)
        XCTAssertEqual(breakdown[0].stars, 2)
        XCTAssertEqual(breakdown[0].count, 2)
        XCTAssertEqual(breakdown[0].name, "复杂")
        XCTAssertEqual(breakdown[1].stars, 3)
        XCTAssertEqual(breakdown[1].count, 1)
        XCTAssertEqual(breakdown[1].name, "不舍")
        XCTAssertEqual(breakdown[2].stars, 1)
        XCTAssertEqual(breakdown[2].count, 0)
        XCTAssertEqual(breakdown[2].name, "平静")
    }

    func testEmotionBreakdownAllZeroWhenNoEmotionValues() {
        let records = [
            makeRecord(emotionValue: nil),
            makeRecord(emotionValue: nil),
        ]
        let breakdown = StatsCalculator.compute(from: records).emotionBreakdown
        XCTAssertEqual(breakdown.count, 3)
        XCTAssertTrue(breakdown.allSatisfy { $0.count == 0 })
        XCTAssertEqual(breakdown[0].name, "平静")
        XCTAssertEqual(breakdown[2].name, "不舍")
    }

    // MARK: - 集成

    func testIsEmptyFlag() {
        XCTAssertTrue(StatsCalculator.compute(from: []).isEmpty)
        XCTAssertFalse(StatsCalculator.compute(from: [makeRecord()]).isEmpty)
    }

    // MARK: - 闰年

    func testLeapYearCompanionshipDays() {
        let records = [
            makeRecord(
                farewellDate: date(year: 2024, month: 3, day: 1),
                purchaseDate: date(year: 2024, month: 2, day: 28)
            )
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertEqual(stats.averageCompanionshipDays!, 2)
        XCTAssertEqual(stats.longestCompanionshipDays, 2, accuracy: 0)
    }

    func testSingleDayCompanionship() {
        let records = [
            makeRecord(
                farewellDate: date(year: 2024, month: 6, day: 15),
                purchaseDate: date(year: 2024, month: 6, day: 15)
            )
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertEqual(stats.averageCompanionshipDays!, 0)
        XCTAssertEqual(stats.longestCompanionshipDays, 0, accuracy: 0)
    }

    // MARK: - 自定义分类

    func testCategoryBreakdownWithCustomCategories() throws {
        let container = makeContainerForStatsTests()
        let context = ModelContext(container)
        let cat1 = UserCategory(name: "数码", iconName: "tag", sortOrder: 0)
        let cat2 = UserCategory(name: "服饰", iconName: "tag", sortOrder: 1)
        context.insert(cat1)
        context.insert(cat2)

        let r1 = FarewellRecord(name: "a", category: .builtin(.other), method: .donate)
        r1.categoryRaw = AnyCategory.storageIDForDelete(userCategory: cat1)
        let r2 = FarewellRecord(name: "b", category: .builtin(.other), method: .donate)
        r2.categoryRaw = AnyCategory.storageIDForDelete(userCategory: cat1)
        let r3 = FarewellRecord(name: "c", category: .builtin(.other), method: .donate)
        r3.categoryRaw = AnyCategory.storageIDForDelete(userCategory: cat2)
        context.insert(r1); context.insert(r2); context.insert(r3)
        try context.save()

        let stats = StatsCalculator.compute(from: [r1, r2, r3])
        XCTAssertEqual(stats.categoryBreakdown.count, 2)
        XCTAssertEqual(stats.categoryBreakdown.first?.count, 2, "数码 应有 2 条")
    }

    // MARK: - Equatable

    func testFarewellStatsEquatable() {
        let a = FarewellStats(
            totalCount: 3,
            averageCompanionshipDays: 3,
            longestCompanionshipDays: 5,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: .builtin(FarewellCategory.books), count: 3)],
            categoryPriceBreakdown: [CategoryPriceCount(category: .builtin(FarewellCategory.books), totalPrice: 300)],
            methodBreakdown: [MethodCount(name: "捐赠", icon: "heart", count: 2)],
            emotionBreakdown: [EmotionCount(stars: 1, name: "平静", count: 1)]
        )
        let b = FarewellStats(
            totalCount: 3,
            averageCompanionshipDays: 3,
            longestCompanionshipDays: 5,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: .builtin(FarewellCategory.books), count: 3)],
            categoryPriceBreakdown: [CategoryPriceCount(category: .builtin(FarewellCategory.books), totalPrice: 300)],
            methodBreakdown: [MethodCount(name: "捐赠", icon: "heart", count: 2)],
            emotionBreakdown: [EmotionCount(stars: 1, name: "平静", count: 1)]
        )
        XCTAssertEqual(a, b, "FarewellStats 应可比较相等")
    }

    // MARK: - 辅助

    private func makeContainerForStatsTests() -> ModelContainer {
        let schema = Schema([FarewellRecord.self, UserCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
