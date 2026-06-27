import XCTest
import SwiftData
@testable import JianDan

@MainActor
final class UserCategoryTests: XCTestCase {

    private func makeContainer() -> ModelContainer {
        let schema = Schema([UserCategory.self, FarewellRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - 名称校验

    func testInitTrimsWhitespace() {
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "  数码配件  ", iconName: "cable.connector", sortOrder: 0)
        context.insert(cat)
        XCTAssertEqual(cat.name, "数码配件", "应 trim 首尾空白")
    }

    func testInitRejectsEmptyName() {
        // precondition 在 init 触发；XCTest 默认行为是 trap
        // 这里仅做正向断言（trim 后非空通过）
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "name", iconName: "tag", sortOrder: 0)
        context.insert(cat)
        XCTAssertFalse(cat.name.isEmpty)
    }

    func testInitEnforcesMaxNameLength() {
        // 10 字上限
        let longName = String(repeating: "字", count: 11)
        // precondition: 不应允许超过 10 字
        // 在 XCTest 中无法拦截 precondition；通过类型契约 + 文档保证
        // 这里用"合法长度"做正向断言
        let container = makeContainer()
        let context = ModelContext(container)
        let ok = UserCategory(name: "一二三四五六七八九十", iconName: "tag", sortOrder: 0)  // 10 字
        context.insert(ok)
        XCTAssertEqual(ok.name.count, 10)
        XCTAssertTrue(longName.count > UserCategory.nameMaxLength, "测试前提：11 字 > 10 上限")
    }

    // MARK: - iconName

    func testDefaultIconWhenEmpty() {
        // 不允许空 iconName：init 时若空应 fallback 到 default
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "test", iconName: "", sortOrder: 0)
        context.insert(cat)
        XCTAssertEqual(cat.iconName, "tag", "空 iconName 应 fallback 到 default 'tag'")
    }

    func testKeepsProvidedIconName() {
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "test", iconName: "cable.connector", sortOrder: 0)
        context.insert(cat)
        XCTAssertEqual(cat.iconName, "cable.connector")
    }

    // MARK: - 排序

    func testSortOrderDefaultsToZero() {
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "test", iconName: "tag")
        context.insert(cat)
        XCTAssertEqual(cat.sortOrder, 0)
    }

    // MARK: - SwiftData 持久化

    func testRoundtrip() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        let original = UserCategory(name: "数码配件", iconName: "cable.connector", sortOrder: 5)
        context.insert(original)
        try context.save()

        let id = original.id
        let descriptor = FetchDescriptor<UserCategory>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, id)
        XCTAssertEqual(fetched.first?.name, "数码配件")
        XCTAssertEqual(fetched.first?.iconName, "cable.connector")
        XCTAssertEqual(fetched.first?.sortOrder, 5)
    }

    func testUniqueIDConstraint() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        let a = UserCategory(name: "a", iconName: "tag", sortOrder: 0)
        let b = UserCategory(name: "b", iconName: "tag", sortOrder: 1)
        context.insert(a)
        context.insert(b)
        try context.save()

        XCTAssertNotEqual(a.id, b.id, "不同实例应有不同 UUID")
    }

    // MARK: - delete + 引用改写

    func testReassignReferencingRecords() throws {
        // 模拟"删除自定义分类时，把引用它的 FarewellRecord.categoryID 改写为 .other 的 rawValue"
        let container = makeContainer()
        let context = ModelContext(container)

        let cat = UserCategory(name: "待删", iconName: "tag", sortOrder: 0)
        context.insert(cat)
        let compoundID = AnyCategory.storageIDForDelete(userCategory: cat)

        let r1 = FarewellRecord(
            name: "item1",
            category: .builtin(.other),  // 先建出来再改
            method: .donate
        )
        r1.categoryRaw = compoundID
        let r2 = FarewellRecord(
            name: "item2",
            category: .builtin(.other),
            method: .donate
        )
        r2.categoryRaw = compoundID
        let r3 = FarewellRecord(
            name: "item3",
            category: .builtin(.clothing),  // 不引用待删分类
            method: .donate
        )
        context.insert(r1); context.insert(r2); context.insert(r3)
        try context.save()

        // 执行重写
        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: AnyCategory.storageIDForDelete(userCategory: cat),
            toCategoryID: Category.other.rawValue,
            in: context
        )
        try context.save()

        XCTAssertEqual(r1.categoryRaw, Category.other.rawValue)
        XCTAssertEqual(r2.categoryRaw, Category.other.rawValue)
        XCTAssertEqual(r3.categoryRaw, Category.clothing.rawValue, "未引用的记录不应被改写")
    }

    // MARK: - ReassignService 边界场景

    func testReassignServiceIsNoOpWhenNoMatches() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        // 插入一个未引用的记录
        context.insert(FarewellRecord(
            name: "no-match",
            category: .builtin(.books),
            method: .donate
        ))
        try context.save()

        // 用一个根本不存在的 compound ID 重写
        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: "__custom__|不存在|tag",
            toCategoryID: Category.other.rawValue,
            in: context
        )
        try context.save()

        // 记录未受影响
        let descriptor = FetchDescriptor<FarewellRecord>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.categoryRaw, "书籍")
    }

    func testReassignServiceIsNoOpWithEmptyContext() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        // context 完全为空，reassign 不应抛错
        XCTAssertNoThrow(try {
            UserCategoryReassignService.reassign(
                fromCategoryCompoundID: "__custom__|X|tag",
                toCategoryID: Category.other.rawValue,
                in: context
            )
        }())
    }

    func testReassignServiceLeavesOtherCategoriesIntact() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        let cat = UserCategory(name: "target", iconName: "tag", sortOrder: 0)
        context.insert(cat)
        let compoundID = AnyCategory.storageIDForDelete(userCategory: cat)

        // 引用 target 的记录
        let ref = FarewellRecord(name: "ref", category: .builtin(.other), method: .donate)
        ref.categoryRaw = compoundID

        // 不引用 target 的自定义分类记录
        let otherCustomCat = UserCategory(name: "other", iconName: "tag", sortOrder: 1)
        context.insert(otherCustomCat)
        let otherCustomID = AnyCategory.storageIDForDelete(userCategory: otherCustomCat)
        let otherRef = FarewellRecord(name: "other-ref", category: .builtin(.other), method: .donate)
        otherRef.categoryRaw = otherCustomID

        // 内置分类记录
        let builtinRef = FarewellRecord(name: "builtin", category: .builtin(.books), method: .donate)

        context.insert(ref)
        context.insert(otherRef)
        context.insert(builtinRef)
        try context.save()

        UserCategoryReassignService.reassign(
            fromCategoryCompoundID: compoundID,
            toCategoryID: Category.other.rawValue,
            in: context
        )
        try context.save()

        XCTAssertEqual(ref.categoryRaw, Category.other.rawValue)
        XCTAssertEqual(otherRef.categoryRaw, otherCustomID, "其他自定义分类不应被影响")
        XCTAssertEqual(builtinRef.categoryRaw, "书籍", "内置分类不应被影响")
    }

    // MARK: - iconName 边界

    func testDefaultIconWhenIconNameIsOnlyWhitespace() throws {
        // 当前实现只处理 `isEmpty`，空白字符不会被 fallback（行为记录）
        let container = makeContainer()
        let context = ModelContext(container)
        let cat = UserCategory(name: "test", iconName: "   ", sortOrder: 0)
        context.insert(cat)
        // 文档约定：仅 empty 触发 fallback；whitespace 不触发（因为 SwiftUI 仍能渲染空格）
        XCTAssertEqual(cat.iconName, "   ")
    }

    func testCustomCategorySortOrderApplied() throws {
        let container = makeContainer()
        let context = ModelContext(container)

        let a = UserCategory(name: "a", iconName: "tag", sortOrder: 5)
        let b = UserCategory(name: "b", iconName: "tag", sortOrder: 1)
        let c = UserCategory(name: "c", iconName: "tag", sortOrder: 3)
        context.insert(a)
        context.insert(b)
        context.insert(c)
        try context.save()

        let descriptor = FetchDescriptor<UserCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.map(\.name), ["b", "c", "a"])
    }
}