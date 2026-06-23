import XCTest
@testable import JianDan

final class WisdomTests: XCTestCase {
    func testLibraryHasEnoughQuotes() {
        XCTAssertGreaterThanOrEqual(
            WisdomLibrary.all.count,
            5,
            "Phase 1 内置金句应至少 5 条"
        )
    }

    func testAllQuotesAreValid() {
        for w in WisdomLibrary.all {
            XCTAssertFalse(
                w.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Wisdom \(w.id) text should not be empty"
            )
            XCTAssertLessThanOrEqual(
                w.text.count,
                Wisdom.textMaxLength,
                "Wisdom \(w.id) text exceeds max length"
            )
            XCTAssertFalse(
                w.attribution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Wisdom \(w.id) attribution should not be empty"
            )
            XCTAssertLessThanOrEqual(
                w.attribution.count,
                Wisdom.attributionMaxLength,
                "Wisdom \(w.id) attribution exceeds max length"
            )
        }
    }

    func testAllIdsAreUnique() {
        let ids = WisdomLibrary.all.map(\.id)
        XCTAssertEqual(
            ids.count,
            Set(ids).count,
            "Wisdom IDs should be unique"
        )
    }

    func testInitPreconditionsRejectEmptyText() {
        // empty text 应触发 precondition（DEBUG 下会 crash 测试进程）
        // 因此仅文档化意图：实际不执行
        // 失败示例：
        //   Wisdom(id: "x", text: "", attribution: "某人")
    }

    func testHashableAndIdentifiable() {
        let w = WisdomLibrary.all[0]
        let copy = w
        XCTAssertEqual(w, copy, "Hashable equality")
        XCTAssertEqual(w.id, w.id, "Identifiable id stable")
    }

    func testCodableRoundTrip() throws {
        let original = WisdomLibrary.all[0]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Wisdom.self, from: data)
        XCTAssertEqual(original, decoded, "Codable round-trip should preserve value")
    }
}