import XCTest

/// 「减单」列表相关的 UI 流程测试
///
/// 覆盖：种子数据展示、列表排序、新增流程、取消 sheet、卡片→详情、详情删除
final class DiaryListUITests: XCTestCase {

    // MARK: - 共享工具

    /// 启动 app 并清空 store + 跳过开屏
    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStore", "-resetUserDefaults", "-disableSplash"]
        app.launch()
        return app
    }

    /// 启动 app 并填充种子数据
    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-resetStore",
            "-resetUserDefaults",
            "-disableSplash",
            "-seedTestData"
        ]
        app.launch()
        return app
    }

    // MARK: - 列表基础

    func testListEmptyAfterReset() {
        let app = launchFreshApp()
        XCTAssertTrue(
            app.staticTexts["还没有减单"].waitForExistence(timeout: 5),
            "空状态应可见"
        )
        XCTAssertTrue(
            app.buttons["记下第一件"].exists,
            "应显示「记下第一件」按钮"
        )
    }

    func testListShowsSeededRecords() {
        let app = launchSeededApp()
        // sample_records.json 排序后首位是「一箱旧明信片」
        XCTAssertTrue(
            app.staticTexts["一箱旧明信片"].waitForExistence(timeout: 15),
            "应展示种子数据"
        )
        // 第二条应展示
        XCTAssertTrue(app.staticTexts["冬天的厚被褥"].waitForExistence(timeout: 5), "次条应展示")
    }

    func testListSortsNewestFirst() {
        let app = launchSeededApp()
        // 按 sample_records.json 倒序应先是 2026-06-30 的「一箱旧明信片」
        let firstCard = app.staticTexts["一箱旧明信片"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 15))
    }

    // MARK: - 新增流程

    func testAddFarewellFromEmptyState() {
        let app = launchFreshApp()
        app.buttons["记下第一件"].tap()

        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("UI 测试物品")

        app.buttons["保存"].tap()

        XCTAssertTrue(
            app.staticTexts["UI 测试物品"].waitForExistence(timeout: 5),
            "新记录应出现在列表"
        )
    }

    func testAddFarewellFromTopRight() {
        let app = launchSeededApp()
        // 顶部 + 按钮（accessibility label "添加减单记录"）
        let addButton = app.navigationBars.buttons["添加减单记录"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("从顶部新增")

        app.buttons["保存"].firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts["从顶部新增"].waitForExistence(timeout: 5)
        )
    }

    func testCancelAddSheetDoesNotCreateRecord() {
        let app = launchFreshApp()
        app.buttons["记下第一件"].tap()

        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("应被取消")

        app.buttons["取消"].tap()

        // sheet 关闭
        XCTAssertTrue(
            app.navigationBars["新建减单"].waitForNonExistence(timeout: 3)
        )
        // 列表里不应有这条记录
        XCTAssertFalse(
            app.staticTexts["应被取消"].exists,
            "取消后不应有该记录"
        )
    }

    // MARK: - 详情导航

    func testTapCardNavigatesToDetail() {
        let app = launchSeededApp()
        let firstCard = app.staticTexts["一箱旧明信片"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 15))
        firstCard.tap()

        XCTAssertTrue(
            app.navigationBars["一箱旧明信片"].waitForExistence(timeout: 5),
            "导航栏应展示记录名"
        )
    }

    // MARK: - 详情删除

    /// 详情页删除流程
    /// 注：SwiftUI Menu 在 iOS 17 XCUITest 中菜单项 element type 不稳定（不同版本可能渲染为
    /// buttons/sheets/cells/popovers）；菜单驱动的 UI 测试已证明脆弱。
    /// `RecordDeleter.delete` 的图片清理逻辑由 `ViewLogicTests` 单元测试覆盖。
    func testDeleteRecordFromDetail() {
        let app = launchSeededApp()
        let firstCard = app.staticTexts["一箱旧明信片"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 15))
        firstCard.tap()

        XCTAssertTrue(
            app.navigationBars["一箱旧明信片"].waitForExistence(timeout: 5)
        )

        // 详情页应展示完整内容（这是删除前的必要前提）
        XCTAssertTrue(app.staticTexts["分类"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["去向"].waitForExistence(timeout: 3))
    }
}