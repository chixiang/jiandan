import XCTest

/// Smoke test: 启动后根视图为 RootTabView，含 3 个 tab item。
final class JianDanUITests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 验证 Tab Bar 三个 tab item 存在（Task 2 将根视图改为 RootTabView）
        XCTAssertTrue(
            app.tabBars.buttons["减单"].waitForExistence(timeout: 5),
            "Tab '减单' should exist after launch"
        )
        XCTAssertTrue(
            app.tabBars.buttons["极简"].waitForExistence(timeout: 5),
            "Tab '极简' should exist after launch"
        )
        XCTAssertTrue(
            app.tabBars.buttons["我的"].waitForExistence(timeout: 5),
            "Tab '我的' should exist after launch"
        )
    }

    /// 回归测试：池老板反馈 task9 后新建一条减单在列表中看不到。
    /// 流程：进首页 → 点 + → 填名字 → 保存 → 期待列表出现该条记录。
    func testAddFarewellAppearsInList() throws {
        let app = XCUIApplication()
        // 清空 SwiftData store，确保从空状态开始
        app.launchArguments = ["-resetStore", "-resetUserDefaults"]
        app.launch()

        // 1. 已经在「减单」Tab；空状态显示「开始第一次减单」按钮
        XCTAssertTrue(
            app.staticTexts["还没有减单"].waitForExistence(timeout: 5),
            "Empty state should appear on first launch (or if store was empty)"
        )

        // 2. 点 + 按钮（导航栏右上角）
        let addButton = app.navigationBars.buttons["添加减单记录"]
        if !addButton.exists {
            // 兜底：空状态中央也有一个 + 按钮
            let emptyAdd = app.buttons["开始第一次减单"]
            XCTAssertTrue(emptyAdd.waitForExistence(timeout: 3), "Should have a way to add")
            emptyAdd.tap()
        } else {
            addButton.tap()
        }

        // 3. 等待 sheet 出现「新建减单」标题
        XCTAssertTrue(
            app.navigationBars["新建减单"].waitForExistence(timeout: 3),
            "Add sheet should appear"
        )

        // 4. 填名称
        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        nameField.tap()
        nameField.typeText("UI测试减单-蓝色羊毛大衣")

        // 5. 点保存
        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        saveButton.tap()

        // 6. 期待 sheet 关闭
        XCTAssertTrue(
            app.navigationBars["新建减单"].waitForNonExistence(timeout: 5),
            "Sheet should dismiss after save"
        )

        // 7. ★ 核心断言：列表里能看到这条记录
        let created = app.staticTexts["UI测试减单-蓝色羊毛大衣"]
        XCTAssertTrue(
            created.waitForExistence(timeout: 5),
            "Newly created farewell should appear in the diary list"
        )
    }

    /// Task 10 回归测试：「极简」Tab 显示金句列表，点击进入详情（task11 改用 JSON）
    func testWisdomTabShowsQuotes() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStore", "-resetUserDefaults"]
        app.launch()

        // 1. 进「极简」Tab
        XCTAssertTrue(
            app.tabBars.buttons["极简"].waitForExistence(timeout: 5),
            "Tab '极简' should exist"
        )
        app.tabBars.buttons["极简"].tap()

        // 2. 顶部「今日一句」卡片可见
        XCTAssertTrue(
            app.staticTexts["今日一句"].waitForExistence(timeout: 5),
            "Daily quote label should appear"
        )

        // 3. 列表标题可见
        XCTAssertTrue(
            app.staticTexts["全部短文"].exists,
            "List section title should appear"
        )

        // 4. 列表里至少看到 JSON 第一条断舍离短文
        XCTAssertTrue(
            app.staticTexts["拥有得愈少，自由便愈多。"].waitForExistence(timeout: 5),
            "First quote from JSON should appear in list"
        )
        // 验证出处
        XCTAssertTrue(
            app.staticTexts["断舍离·前言"].exists,
            "Attribution should appear in list"
        )

        // 5. 点击进入详情
        app.staticTexts["拥有得愈少，自由便愈多。"].tap()

        // 6. 详情页能看到出处
        XCTAssertTrue(
            app.staticTexts["断舍离·前言"].waitForExistence(timeout: 3),
            "Detail view should show attribution"
        )

        // 7. 返回
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }

    /// Task 12 回归测试：「我的」Tab 显示统计 + 主题设置
    func testProfileTabShowsStatsAndSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStore", "-resetUserDefaults"]
        app.launch()

        // 1. 进「我的」Tab
        XCTAssertTrue(
            app.tabBars.buttons["我的"].waitForExistence(timeout: 5),
            "Tab '我的' should exist"
        )
        app.tabBars.buttons["我的"].tap()

        // 2. 空态提示（清空 store 后无数据）
        XCTAssertTrue(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 5),
            "Empty state should appear"
        )

        // 3. 设置区始终可见：3 个主题选项
        XCTAssertTrue(
            app.staticTexts["外观"].exists,
            "Settings section header should appear"
        )
        // ThemeOptionRow 用 accessibilityElement(children: .combine)，
        // 因此每个 row 暴露为 button（label: "X主题" 或 "X主题，已选中"）。
        // 用 predicate 模糊匹配（包含关系），避免 isSelected 状态拼接干扰。
        let lightPredicate = NSPredicate(format: "label BEGINSWITH '浅色'")
        let darkPredicate = NSPredicate(format: "label BEGINSWITH '深色'")
        let inkPredicate = NSPredicate(format: "label BEGINSWITH '墨色'")

        XCTAssertTrue(
            app.buttons.matching(lightPredicate).firstMatch.waitForExistence(timeout: 2),
            "Light theme button should appear"
        )
        XCTAssertTrue(
            app.buttons.matching(darkPredicate).firstMatch.exists,
            "Dark theme button should appear"
        )
        XCTAssertTrue(
            app.buttons.matching(inkPredicate).firstMatch.exists,
            "Ink theme button should appear"
        )
        // 默认是浅色，应被标记为已选中（label 包含 "已选中"）
        let lightButton = app.buttons.matching(lightPredicate).firstMatch
        let lightLabel = lightButton.label
        XCTAssertTrue(
            lightLabel.contains("已选中"),
            "Light theme should be marked as selected (actual label: \(lightLabel))"
        )
    }
}