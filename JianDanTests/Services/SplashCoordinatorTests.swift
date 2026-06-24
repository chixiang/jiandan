import XCTest
@testable import JianDan

@MainActor
final class SplashCoordinatorTests: XCTestCase {
    // MARK: - 初始状态

    func testInitStartsVisible() {
        let quote = WisdomLibrary.all[0]
        let coordinator = SplashCoordinator(quote: quote, autoDismissSeconds: 5.0)
        XCTAssertTrue(coordinator.isVisible, "Should start visible")
        XCTAssertEqual(coordinator.quote.id, quote.id, "Should hold the injected quote")
        XCTAssertEqual(coordinator.autoDismissSeconds, 5.0, accuracy: 0.001)
    }

    func testInitWithShortAutoDismiss() {
        // 测试可注入更短的秒数（避免真的等 5s）
        let coordinator = SplashCoordinator(
            quote: WisdomLibrary.all[0],
            autoDismissSeconds: 0.1
        )
        XCTAssertEqual(coordinator.autoDismissSeconds, 0.1, accuracy: 0.001)
    }

    // MARK: - dismiss()

    func testDismissChangesVisibility() {
        let coordinator = SplashCoordinator(
            quote: WisdomLibrary.all[0],
            autoDismissSeconds: 5.0
        )
        XCTAssertTrue(coordinator.isVisible)
        coordinator.dismiss()
        XCTAssertFalse(coordinator.isVisible, "dismiss() should flip isVisible to false")
    }

    func testDismissIsIdempotent() {
        let coordinator = SplashCoordinator(
            quote: WisdomLibrary.all[0],
            autoDismissSeconds: 5.0
        )
        coordinator.dismiss()
        coordinator.dismiss()  // 第二次
        coordinator.dismiss()  // 第三次
        XCTAssertFalse(coordinator.isVisible, "Multiple dismiss() calls should be safe")
    }

    // MARK: - RandomSource 集成

    func testRandomQuoteViaSystemSource() {
        // 用系统随机源跑 100 次，至少出现 2 种不同的 id（库里有 10 条）
        let repo = QuoteRepository()
        var seenIds = Set<String>()
        for _ in 0..<100 {
            if let q = repo.randomQuote() {
                seenIds.insert(q.id)
            }
        }
        // 100 次随机抽 10 条，碰撞概率极低；用 >= 2 做最小合理性断言
        XCTAssertGreaterThanOrEqual(
            seenIds.count, 2,
            "System random source should produce variety over 100 calls"
        )
    }
}
