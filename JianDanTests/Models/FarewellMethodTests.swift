import XCTest
@testable import JianDan

final class FarewellMethodTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(FarewellMethod.allCases.count, 6)
    }

    func testRawValues() {
        XCTAssertEqual(FarewellMethod.gift.rawValue, "送人")
        XCTAssertEqual(FarewellMethod.discard.rawValue, "扔掉")
        XCTAssertEqual(FarewellMethod.donate.rawValue, "捐赠")
        XCTAssertEqual(FarewellMethod.resell.rawValue, "二手出售")
        XCTAssertEqual(FarewellMethod.store.rawValue, "暂存")
        XCTAssertEqual(FarewellMethod.other.rawValue, "其他")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(FarewellMethod(rawValue: "送人"), .gift)
        XCTAssertEqual(FarewellMethod(rawValue: "其他"), .other)
        XCTAssertNil(FarewellMethod(rawValue: "未知"))
    }

    func testIconMapping() {
        XCTAssertEqual(FarewellMethod.gift.icon, "gift")
        XCTAssertEqual(FarewellMethod.discard.icon, "trash")
        XCTAssertEqual(FarewellMethod.donate.icon, "heart")
        XCTAssertEqual(FarewellMethod.resell.icon, "tag")
        XCTAssertEqual(FarewellMethod.store.icon, "archivebox")
        XCTAssertEqual(FarewellMethod.other.icon, "ellipsis.circle")
    }
}
