import XCTest
@testable import JianDan

final class CategoryTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Category.allCases.count, 6)
    }

    func testRawValues() {
        XCTAssertEqual(Category.clothing.rawValue, "衣物")
        XCTAssertEqual(Category.books.rawValue, "书籍")
        XCTAssertEqual(Category.electronics.rawValue, "电子")
        XCTAssertEqual(Category.furniture.rawValue, "家具")
        XCTAssertEqual(Category.miscellaneous.rawValue, "杂物")
        XCTAssertEqual(Category.other.rawValue, "其他")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(Category(rawValue: "衣物"), .clothing)
        XCTAssertEqual(Category(rawValue: "其他"), .other)
        XCTAssertNil(Category(rawValue: "不存在"))
    }

    func testIconMapping() {
        XCTAssertEqual(Category.clothing.icon, "tshirt")
        XCTAssertEqual(Category.books.icon, "book")
        XCTAssertEqual(Category.electronics.icon, "laptopcomputer")
        XCTAssertEqual(Category.furniture.icon, "sofa")
        XCTAssertEqual(Category.miscellaneous.icon, "shippingbox")
        XCTAssertEqual(Category.other.icon, "circle.grid.2x2")
    }

    func testIdentifiable() {
        XCTAssertEqual(Category.clothing.id, "衣物")
        XCTAssertTrue(Category.allCases.allSatisfy { !$0.id.isEmpty })
    }
}
