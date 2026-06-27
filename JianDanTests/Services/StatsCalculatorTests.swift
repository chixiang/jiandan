import XCTest
import SwiftData
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
            category: .builtin(category),
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
        XCTAssertEqual(stats.totalPurchasePrice, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertNil(stats.averageEmotion)
        XCTAssertNil(stats.monthLabel)
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

    // MARK: - 本月计数（兼容旧 API：scope 为 nil/allTime 时 thisMonthCount 仍可用）

    func testThisMonthCount() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 1)),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 30)),
            makeRecord(farewellDate: date(year: 2026, month: 5, day: 31)),  // 上月
            makeRecord(farewellDate: date(year: 2026, month: 7, day: 1)),  // 下月
        ]
        let currentMonth = YearMonth.current(referenceDate: now)
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(currentMonth),
            referenceDate: now
        )
        XCTAssertEqual(stats.totalCount, 2)
        XCTAssertEqual(stats.monthLabel, "2026 年 6 月")
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
        XCTAssertEqual(breakdown[0].category, .builtin(.electronics))
        XCTAssertEqual(breakdown[0].count, 3)
        XCTAssertEqual(breakdown[1].category, .builtin(.clothing))
        XCTAssertEqual(breakdown[2].category, .builtin(.books))
    }

    func testFarewellStatsEquatable() {
        let a = FarewellStats(
            totalCount: 3,
            totalCompanionshipDays: 10,
            longestCompanionshipDays: 5,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: .builtin(FarewellCategory.books), count: 3)],
            averageEmotion: 4.0,
            monthLabel: "2026 年 6 月"
        )
        let b = FarewellStats(
            totalCount: 3,
            totalCompanionshipDays: 10,
            longestCompanionshipDays: 5,
            totalPurchasePrice: 100,
            categoryBreakdown: [CategoryCount(category: .builtin(FarewellCategory.books), count: 3)],
            averageEmotion: 4.0,
            monthLabel: "2026 年 6 月"
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

    // MARK: - 按月切片（scope = .month）

    func testMonthScopeOnlyCountsMatchingMonth() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(name: "a", category: .clothing, farewellDate: date(year: 2026, month: 6, day: 1)),
            makeRecord(name: "b", category: .books,    farewellDate: date(year: 2026, month: 6, day: 30)),
            makeRecord(name: "c", category: .electronics, farewellDate: date(year: 2026, month: 5, day: 31)),  // 上月
            makeRecord(name: "d", category: .other,    farewellDate: date(year: 2026, month: 7, day: 1)),  // 下月
        ]
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(YearMonth(year: 2026, month: 6)),
            referenceDate: now
        )
        XCTAssertEqual(stats.totalCount, 2, "6 月只计入 2 条")
        XCTAssertEqual(stats.categoryBreakdown.count, 2)
        XCTAssertEqual(stats.categoryBreakdown.map(\.category).sorted { $0.displayName < $1.displayName },
                       [AnyCategory.builtin(FarewellCategory.books), AnyCategory.builtin(FarewellCategory.clothing)])
        XCTAssertEqual(stats.monthLabel, "2026 年 6 月")
    }

    func testMonthScopeEmptyWhenNoRecordsInThatMonth() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 5, day: 1)),
        ]
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(YearMonth(year: 2026, month: 6)),
            referenceDate: now
        )
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertNil(stats.averageEmotion)
        XCTAssertTrue(stats.isEmpty)
    }

    func testMonthScopeCompanionshipAndPriceRestrictToMonth() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            // 6 月：陪伴 100 天 / 价 200
            makeRecord(
                farewellDate: date(year: 2026, month: 6, day: 10),
                purchaseDate: date(year: 2026, month: 3, day: 2),
                purchasePrice: 200
            ),
            // 5 月：陪伴 365 天 / 价 1000（不应计入 6 月）
            makeRecord(
                farewellDate: date(year: 2026, month: 5, day: 1),
                purchaseDate: date(year: 2025, month: 5, day: 1),
                purchasePrice: 1000
            ),
        ]
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(YearMonth(year: 2026, month: 6)),
            referenceDate: now
        )
        XCTAssertEqual(stats.totalCount, 1)
        XCTAssertEqual(stats.totalCompanionshipDays, 100, accuracy: 2)
        XCTAssertEqual(stats.longestCompanionshipDays, 100, accuracy: 2)
        XCTAssertEqual(stats.totalPurchasePrice, 200, accuracy: 0.01)
    }

    func testMonthScopeAverageEmotionOnlyIncludesMonthRecords() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 5), emotionValue: 4),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 10), emotionValue: 2),
            makeRecord(farewellDate: date(year: 2026, month: 5, day: 1), emotionValue: 5),  // 不计
        ]
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(YearMonth(year: 2026, month: 6)),
            referenceDate: now
        )
        XCTAssertEqual(stats.averageEmotion!, 3.0, accuracy: 0.01)
    }

    // MARK: - 累计 scope（默认）

    func testAllTimeScopeIgnoresMonthFilter() {
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 1)),
            makeRecord(farewellDate: date(year: 2026, month: 5, day: 1)),
            makeRecord(farewellDate: date(year: 2025, month: 12, day: 1)),
        ]
        let stats = StatsCalculator.compute(from: records, referenceDate: now)
        XCTAssertEqual(stats.totalCount, 3)
        XCTAssertNil(stats.monthLabel, "累计态 monthLabel 应为 nil")
    }

    // MARK: - 月份枚举

    func testMonthsWithRecordsReturnsSortedDescending() {
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 5)),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 20)),
            makeRecord(farewellDate: date(year: 2025, month: 12, day: 1)),
            makeRecord(farewellDate: date(year: 2026, month: 3, day: 1)),
            makeRecord(farewellDate: date(year: 2024, month: 8, day: 1)),
        ]
        let months = StatsCalculator.monthsWithRecords(in: records)
        XCTAssertEqual(months.count, 4)
        XCTAssertEqual(months[0], YearMonth(year: 2026, month: 6))
        XCTAssertEqual(months[1], YearMonth(year: 2026, month: 3))
        XCTAssertEqual(months[2], YearMonth(year: 2025, month: 12))
        XCTAssertEqual(months[3], YearMonth(year: 2024, month: 8))
    }

    func testMonthsWithRecordsEmpty() {
        XCTAssertTrue(StatsCalculator.monthsWithRecords(in: []).isEmpty)
    }

    func testCurrentMonthHelper() {
        let now = date(year: 2026, month: 6, day: 15)
        let ym = YearMonth.current(referenceDate: now)
        XCTAssertEqual(ym.year, 2026)
        XCTAssertEqual(ym.month, 6)
    }

    // MARK: - 闰年

    func testLeapYearCompanionshipDays() {
        // 2024-02-28 购入 → 2024-03-01 告别，应经过 2 天（闰年 2 月有 29 日）
        let records = [
            makeRecord(
                farewellDate: date(year: 2024, month: 3, day: 1),
                purchaseDate: date(year: 2024, month: 2, day: 28)
            )
        ]
        let stats = StatsCalculator.compute(from: records)
        XCTAssertEqual(stats.totalCompanionshipDays, 2, accuracy: 0)
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
        XCTAssertEqual(stats.totalCompanionshipDays, 0, accuracy: 0)
        XCTAssertEqual(stats.longestCompanionshipDays, 0, accuracy: 0)
    }

    // MARK: - 自定义分类

    func testMonthScopeWithCustomCategoryEncoded() throws {
        let container = makeContainerForStatsTests()
        let context = ModelContext(container)
        let custom = UserCategory(name: "数码配件", iconName: "tag", sortOrder: 0)
        context.insert(custom)

        let now = date(year: 2026, month: 6, day: 15)
        let compoundID = AnyCategory.storageIDForDelete(userCategory: custom)
        let record = FarewellRecord(
            name: "测试",
            category: .builtin(.other),
            farewellDate: date(year: 2026, month: 6, day: 5),
            method: .donate
        )
        record.categoryRaw = compoundID
        context.insert(record)
        try context.save()

        let stats = StatsCalculator.compute(
            from: [record],
            scope: .month(YearMonth(year: 2026, month: 6)),
            referenceDate: now
        )
        XCTAssertEqual(stats.totalCount, 1)
        XCTAssertEqual(stats.categoryBreakdown.first?.category, AnyCategory.custom(name: "数码配件", iconName: "tag"))
    }

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

    // MARK: - 自定义 Calendar

    func testComputeRespectsCustomCalendar() {
        // 用 UTC 日历 + 构造 UTC 时区的日期；scope 过滤应仍能命中
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        // 构造 2026-06-15 UTC
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        let refDate = utcCalendar.date(from: components)!

        // 构造 2026-06-01 UTC 时刻的记录
        components.day = 1
        let farewellDate = utcCalendar.date(from: components)!

        let records = [
            makeRecord(farewellDate: farewellDate)
        ]
        let stats = StatsCalculator.compute(
            from: records,
            scope: .month(YearMonth(year: 2026, month: 6)),
            calendar: utcCalendar,
            referenceDate: refDate
        )
        XCTAssertEqual(stats.totalCount, 1)
        XCTAssertEqual(stats.monthLabel, "2026 年 6 月")
    }

    // MARK: - 月份枚举去重

    func testMonthsWithRecordsDeduplicatesSameMonth() {
        let records = [
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 1)),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 15)),
            makeRecord(farewellDate: date(year: 2026, month: 6, day: 30)),
        ]
        let months = StatsCalculator.monthsWithRecords(in: records)
        XCTAssertEqual(months.count, 1, "6 月 3 条记录应只产出 1 个 YearMonth")
        XCTAssertEqual(months.first?.month, 6)
    }

    // MARK: - AllTime + Calendar 边界

    func testAllTimeScopeIgnoresCalendarMonthBoundary() {
        // scope = .allTime 时，无论 referenceDate 是什么，都统计全部
        let now = date(year: 2026, month: 6, day: 15)
        let records = [
            makeRecord(farewellDate: date(year: 2025, month: 12, day: 31)),
            makeRecord(farewellDate: date(year: 2026, month: 1, day: 1)),
        ]
        let stats = StatsCalculator.compute(from: records, scope: .allTime, referenceDate: now)
        XCTAssertEqual(stats.totalCount, 2)
        XCTAssertNil(stats.monthLabel)
    }

    // MARK: - 辅助

    private func makeContainerForStatsTests() -> ModelContainer {
        let schema = Schema([FarewellRecord.self, UserCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }
}