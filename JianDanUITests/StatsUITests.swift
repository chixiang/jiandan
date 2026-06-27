import XCTest

/// 「我的」Tab 统计相关 UI 测试
final class StatsUITests: XCTestCase {

    // MARK: - 共享工具

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStore", "-resetUserDefaults", "-disableSplash"]
        app.launch()
        return app
    }

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

    private func openProfile(_ app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["我的"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
    }

    // MARK: - 空态

    func testStatsEmptyAfterLaunch() {
        let app = launchFreshApp()
        openProfile(app)

        XCTAssertTrue(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 5),
            "空状态应可见"
        )
        // "统计" 标题在空态下不渲染（ProfileView 仅在 stats.isEmpty == false 时显示 StatsView）
        // 但设置区应仍可见
        XCTAssertTrue(app.staticTexts["外观"].exists, "设置区应仍可见")
    }

    // MARK: - 有数据时填充

    func testStatsPopulateAfterAddingRecord() {
        let app = launchFreshApp()

        // 先建一条
        app.tabBars.buttons["减单"].tap()
        app.buttons["记下第一件"].tap()
        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("统计测试物品")
        app.buttons["保存"].tap()

        XCTAssertTrue(
            app.staticTexts["统计测试物品"].waitForExistence(timeout: 5)
        )

        // 进「我的」
        openProfile(app)

        XCTAssertFalse(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 2),
            "应有数据后空态应消失"
        )
        XCTAssertTrue(
            app.staticTexts["告别数"].waitForExistence(timeout: 3),
            "告别数标签应可见"
        )
    }

    // MARK: - 种子数据下统计

    func testStatsShowWithSeededData() {
        let app = launchSeededApp()
        openProfile(app)

        XCTAssertTrue(
            app.staticTexts["告别数"].waitForExistence(timeout: 5),
            "种子数据下应展示统计"
        )
        // 分类分布标题
        XCTAssertTrue(app.staticTexts["分类分布"].exists)
    }

    // MARK: - 月份选择器

    func testMonthScopeSelectorExists() {
        let app = launchSeededApp()
        openProfile(app)

        // 顶部 Menu 标签：默认「累计」
        let scopeLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '累计'")
        ).firstMatch
        XCTAssertTrue(
            scopeLabel.waitForExistence(timeout: 3),
            "应展示「累计」scope 标签"
        )
    }

    func testMonthScopeFiltering() {
        let app = launchSeededApp()
        openProfile(app)

        // 点 scope 标签展开 menu
        let scopeLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '累计'")
        ).firstMatch
        XCTAssertTrue(scopeLabel.waitForExistence(timeout: 3))
        scopeLabel.tap()

        // 应至少有一个月份可选项（"年 X 月"）
        let monthOption = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '年' AND label CONTAINS '月'")
        ).firstMatch
        if monthOption.waitForExistence(timeout: 3) {
            monthOption.tap()
            // 标题应更新（变成具体月份）
            XCTAssertTrue(
                app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS '年' AND label CONTAINS '月'")
                ).firstMatch.waitForExistence(timeout: 3),
                "选择月份后标题应更新"
            )
        }
    }
}