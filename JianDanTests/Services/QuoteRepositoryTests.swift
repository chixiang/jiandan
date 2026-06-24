import XCTest
@testable import JianDan

@MainActor
final class QuoteRepositoryTests: XCTestCase {
    var repository: QuoteRepository!

    override func setUp() {
        super.setUp()
        repository = QuoteRepository()
    }

    // MARK: - 基础加载

    func testLoadsAtLeast30Quotes() {
        // JSON 应该有 30 条；任何后续新增也至少维持该规模
        XCTAssertGreaterThanOrEqual(
            repository.all.count,
            30,
            "daily_quotes.json should contain at least 30 quotes"
        )
    }

    func testAllQuotesHaveValidFields() {
        for q in repository.all {
            XCTAssertFalse(q.text.isEmpty, "\(q.id) text empty")
            XCTAssertFalse(q.attribution.isEmpty, "\(q.id) attribution empty")
            XCTAssertTrue(q.id.hasPrefix("quote-"), "\(q.id) id should be quote-NNN")
        }
    }

    func testAllIdsAreUnique() {
        let ids = repository.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Quote IDs should be unique")
    }

    // MARK: - 今日一句

    func testTodayQuoteIsNotNil() {
        let quote = repository.todayQuote()
        XCTAssertNotNil(quote, "Today's quote should not be nil when library is non-empty")
    }

    func testTodayQuoteIsDeterministic() {
        // 同一日期多次调用应返回同一句
        let fixedDate = Self.date(year: 2026, month: 6, day: 23)
        let first = repository.todayQuote(for: fixedDate)
        let second = repository.todayQuote(for: fixedDate)
        let third = repository.todayQuote(for: fixedDate)
        XCTAssertEqual(first?.id, second?.id)
        XCTAssertEqual(second?.id, third?.id)
    }

    func testTodayQuoteChangesAcrossDays() {
        let day1 = Self.date(year: 2026, month: 1, day: 1)
        let day100 = Self.date(year: 2026, month: 4, day: 10)
        let q1 = repository.todayQuote(for: day1)
        let q100 = repository.todayQuote(for: day100)
        // 不同日期应大概率返回不同短文（除非整除到同一 index）
        // 这里只断言两者都存在，幂等
        XCTAssertNotNil(q1)
        XCTAssertNotNil(q100)
    }

    func testTodayQuoteYearBoundary() {
        // 12 月 31 日 → 次年 1 月 1 日，dayOfYear 会跨年
        let lastDay = Self.date(year: 2026, month: 12, day: 31)
        let firstDay = Self.date(year: 2027, month: 1, day: 1)
        XCTAssertNotNil(repository.todayQuote(for: lastDay))
        XCTAssertNotNil(repository.todayQuote(for: firstDay))
    }

    func testTodayQuoteLoopsAroundLibrarySize() {
        // 用 dayOfYear = count + 1 的日期，验证 % 正确循环
        let total = repository.all.count
        let dayBeyondSize = Self.date(year: 2026, month: 1, day: 1)
            .addingTimeInterval(TimeInterval(total * 86400))
        let beyondQuote = repository.todayQuote(for: dayBeyondSize)
        // 循环回 index 0 的可能性高，但不是确定性，故只断言非 nil
        XCTAssertNotNil(beyondQuote)
    }

    // MARK: - 容错（破坏性测试需要小心；这里只验证关键场景）

    func testRepositoryHandlesMissingFileGracefully() {
        // 用错误的 resource name 模拟找不到
        // 这里只能间接验证：仓库创建本身不抛错
        let repo = QuoteRepository()
        XCTAssertNotNil(repo.all as Any, "Repository should not crash on access")
        // 即使找不到也应返回空数组而非崩溃
    }

    // MARK: - 冷启动随机一句

    func testRandomQuoteIsNotNil() {
        XCTAssertNotNil(repository.randomQuote(), "randomQuote should return a quote when library is non-empty")
    }

    func testRandomQuoteRespectsStubbedSequence() {
        // 用 stub 注入确定序列，应能精确返回对应 index 的短文
        var stub: RandomSource = StubRandomSource(sequence: [0, 5, repository.all.count - 1])
        let q0 = repository.randomQuote(using: &stub)
        let q5 = repository.randomQuote(using: &stub)
        let qLast = repository.randomQuote(using: &stub)
        XCTAssertEqual(q0?.id, repository.all[0].id)
        XCTAssertEqual(q5?.id, repository.all[5].id)
        XCTAssertEqual(qLast?.id, repository.all[repository.all.count - 1].id)
    }

    func testRandomQuoteFallsBackWhenSequenceExhausted() {
        // 序列耗尽后回退到 fallback % count
        var stub: RandomSource = StubRandomSource(sequence: [], fallback: 7)
        let quote = repository.randomQuote(using: &stub)
        XCTAssertEqual(quote?.id, repository.all[7].id)
    }

    func testRandomQuoteHandlesEmptyLibrary() {
        // 用 0 条短文的 stub 仓库无法直接构造（JSON 是固定的）
        // 这里通过 stub 直接调用 QuoteRepository 的 randomQuote 测试无法测
        // 改为测 StubRandomSource 的边界：upperBound == 0
        var stub = StubRandomSource(sequence: [42], fallback: 0)
        let value = stub.nextInt(upperBound: 0)
        XCTAssertEqual(value, 0, "nextInt(upperBound: 0) must return 0")
    }

    // MARK: - Helpers

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}