import XCTest
@testable import JianDan

/// `AnyCategory` 编码解码测试 —— 覆盖 `Category.swift:44, 80-100` 的
/// `__custom__|name|iconName` 协议，这是项目中最脆弱的代码路径。
final class AnyCategoryTests: XCTestCase {

    // MARK: - storageID 编码

    func testBuiltinStorageIDUsesRawValue() {
        XCTAssertEqual(
            AnyCategory.builtin(.clothing).storageID,
            "衣物"
        )
        XCTAssertEqual(
            AnyCategory.builtin(.electronics).storageID,
            "电子"
        )
        XCTAssertEqual(
            AnyCategory.builtin(.other).storageID,
            "其他"
        )
    }

    func testCustomStorageIDEncodedWithPrefix() {
        let cat = AnyCategory.custom(name: "数码配件", iconName: "cable.connector")
        XCTAssertEqual(
            cat.storageID,
            "__custom__|数码配件|cable.connector"
        )
    }

    func testCustomStorageIDIncludesIconName() {
        let cat = AnyCategory.custom(name: "X", iconName: "star")
        XCTAssertTrue(cat.storageID.contains("|star"))
        XCTAssertTrue(cat.storageID.hasPrefix("__custom__|"))
    }

    // MARK: - resolve() 解码

    func testResolveBuiltinRoundTrip() {
        for category in Category.allCases {
            let encoded = AnyCategory.builtin(category).storageID
            let resolved = AnyCategory.resolve(storageID: encoded)
            XCTAssertEqual(resolved, .builtin(category))
        }
    }

    func testResolveCustomRoundTrip() {
        let original = AnyCategory.custom(name: "宠物用品", iconName: "pawprint")
        let encoded = original.storageID
        let resolved = AnyCategory.resolve(storageID: encoded)
        XCTAssertEqual(resolved, original)
    }

    func testResolveUnknownFallsBackToOther() {
        let resolved = AnyCategory.resolve(storageID: "完全不存在的字符串")
        XCTAssertEqual(resolved, .builtin(.other))
    }

    func testResolveEmptyFallsBackToOther() {
        XCTAssertEqual(AnyCategory.resolve(storageID: ""), .builtin(.other))
    }

    func testResolveMalformedCustomFallsBackToOther() {
        // __custom__ 前缀但缺少 |icon 部分
        let malformed = "__custom__|onlyNameNoIcon"
        XCTAssertEqual(AnyCategory.resolve(storageID: malformed), .builtin(.other))
    }

    func testResolvePrefixAloneFallsBackToOther() {
        // 只有前缀，没有任何内容
        XCTAssertEqual(AnyCategory.resolve(storageID: "__custom__|"), .builtin(.other))
    }

    // MARK: - from(userCategory:)

    func testFromUserCategoryPreservesFields() {
        let userCat = UserCategory(name: "测试分类", iconName: "tag")
        let anyCat = AnyCategory.from(userCategory: userCat)
        XCTAssertEqual(anyCat.displayName, "测试分类")
        XCTAssertEqual(anyCat.iconName, "tag")
    }

    // MARK: - storageIDForDelete()

    func testStorageIDForDeleteMatchesCustomEncode() {
        let userCat = UserCategory(name: "test", iconName: "tag")
        let deleteID = AnyCategory.storageIDForDelete(userCategory: userCat)
        let anyCat = AnyCategory.custom(name: "test", iconName: "tag")
        XCTAssertEqual(deleteID, anyCat.storageID)
    }

    // MARK: - isDeletable

    func testIsDeletableOnlyForCustom() {
        XCTAssertFalse(AnyCategory.builtin(.clothing).isDeletable)
        XCTAssertFalse(AnyCategory.builtin(.other).isDeletable)
        XCTAssertTrue(AnyCategory.custom(name: "x", iconName: "tag").isDeletable)
    }

    // MARK: - Hashable

    func testHashableAllowsUseInSet() {
        let a = AnyCategory.custom(name: "x", iconName: "tag")
        let b = AnyCategory.custom(name: "x", iconName: "tag")
        let c = AnyCategory.custom(name: "y", iconName: "tag")

        let set: Set<AnyCategory> = [a, b, c]
        XCTAssertEqual(set.count, 2, "相同 name+icon 应去重")
    }

    func testHashableDistinguishesBuiltinAndCustom() {
        // "__custom__|衣物|tag" 与 "衣物" 哈希值不同
        let builtin = AnyCategory.builtin(.clothing)
        let custom = AnyCategory.custom(name: "衣物", iconName: "tag")
        XCTAssertNotEqual(builtin, custom)
    }

    // MARK: - displayName / iconName

    func testDisplayName() {
        XCTAssertEqual(AnyCategory.builtin(.books).displayName, "书籍")
        XCTAssertEqual(AnyCategory.custom(name: "我的类目", iconName: "x").displayName, "我的类目")
    }

    func testIconName() {
        XCTAssertEqual(AnyCategory.builtin(.tools).iconName, "wrench.and.screwdriver")
        XCTAssertEqual(AnyCategory.custom(name: "x", iconName: "star.fill").iconName, "star.fill")
    }
}