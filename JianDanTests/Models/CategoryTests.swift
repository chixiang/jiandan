import XCTest
@testable import JianDan

final class CategoryTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Category.allCases.count, 12)
    }

    func testRawValues() {
        XCTAssertEqual(Category.clothing.rawValue, "衣物")
        XCTAssertEqual(Category.shoesAccessories.rawValue, "鞋包配饰")
        XCTAssertEqual(Category.books.rawValue, "书籍")
        XCTAssertEqual(Category.electronics.rawValue, "电子")
        XCTAssertEqual(Category.furniture.rawValue, "家具")
        XCTAssertEqual(Category.homeStorage.rawValue, "家居收纳")
        XCTAssertEqual(Category.beauty.rawValue, "美妆护肤")
        XCTAssertEqual(Category.documents.rawValue, "票据文件")
        XCTAssertEqual(Category.toysCollectibles.rawValue, "玩具收藏")
        XCTAssertEqual(Category.tools.rawValue, "工具器材")
        XCTAssertEqual(Category.miscellaneous.rawValue, "杂物")
        XCTAssertEqual(Category.other.rawValue, "其他")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(Category(rawValue: "衣物"), .clothing)
        XCTAssertEqual(Category(rawValue: "鞋包配饰"), .shoesAccessories)
        XCTAssertEqual(Category(rawValue: "家居收纳"), .homeStorage)
        XCTAssertEqual(Category(rawValue: "其他"), .other)
        XCTAssertNil(Category(rawValue: "不存在"))
    }

    func testIconMapping() {
        XCTAssertEqual(Category.clothing.icon, "tshirt")
        XCTAssertEqual(Category.shoesAccessories.icon, "bag")
        XCTAssertEqual(Category.books.icon, "book")
        XCTAssertEqual(Category.electronics.icon, "laptopcomputer")
        XCTAssertEqual(Category.furniture.icon, "sofa")
        XCTAssertEqual(Category.homeStorage.icon, "shippingbox.and.arrow.backward")
        XCTAssertEqual(Category.beauty.icon, "sparkles")
        XCTAssertEqual(Category.documents.icon, "doc.text")
        XCTAssertEqual(Category.toysCollectibles.icon, "gamecontroller")
        XCTAssertEqual(Category.tools.icon, "wrench.and.screwdriver")
        XCTAssertEqual(Category.miscellaneous.icon, "shippingbox")
        XCTAssertEqual(Category.other.icon, "circle.grid.2x2")
    }

    func testIdentifiable() {
        XCTAssertEqual(Category.clothing.id, "衣物")
        XCTAssertTrue(Category.allCases.allSatisfy { !$0.id.isEmpty })
    }
}
