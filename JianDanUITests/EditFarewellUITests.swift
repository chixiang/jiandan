import XCTest

/// 编辑流程的 UI 测试
///
/// 注：SwiftUI Menu 在 iOS 17 的 XCUITest 中渲染不稳定（菜单项 element type 在不同版本间有差异）。
/// 因此这里只测试可以从外部直接进入编辑表单的路径（通过卡片 → 详情页 → ...）。
/// `EditFarewellSaver` 的截断 / 保存逻辑由 `ViewLogicTests` 单元测试覆盖。
final class EditFarewellUITests: XCTestCase {

    // MARK: - 共享工具

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

    // MARK: - 流程

    /// 进入详情页：详情页应展示所有字段
    /// （菜单打开编辑表单的路径不稳定，跳过；EditFarewellSaver 逻辑由 ViewLogicTests 覆盖）
    func testOpenDetailShowsAllFields() {
        let app = launchSeededApp()
        let firstCard = app.staticTexts["一箱旧明信片"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()

        // 详情页 navigationBar 应展示记录名
        XCTAssertTrue(
            app.navigationBars["一箱旧明信片"].waitForExistence(timeout: 5),
            "导航栏应展示记录名"
        )

        // 详情页应有「分类」「去向」等 section 标签
        XCTAssertTrue(app.staticTexts["分类"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["去向"].exists)
    }

    /// 减单一言存在时应在详情页可见
    func testDetailShowsFarewellLetter() {
        let app = launchSeededApp()
        // 选择有 farewellLetter 的记录：「冬天的厚被褥」
        let card = app.staticTexts["冬天的厚被褥"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()

        XCTAssertTrue(
            app.navigationBars["冬天的厚被褥"].waitForExistence(timeout: 5)
        )

        // 减单一言 section 应可见
        XCTAssertTrue(
            app.staticTexts["减单一言"].waitForExistence(timeout: 3)
        )
    }

    /// 「陪伴了 X 天」在有购入日期时展示
    func testDetailShowsCompanionshipDays() {
        let app = launchSeededApp()
        // 「冬天的厚被褥」购入 2024-01-10，告别 2026-06-01，约 507 天
        let card = app.staticTexts["冬天的厚被褥"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()

        XCTAssertTrue(
            app.navigationBars["冬天的厚被褥"].waitForExistence(timeout: 5)
        )

        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS '陪伴了'")
            ).firstMatch.waitForExistence(timeout: 3),
            "应展示陪伴天数"
        )
    }
}