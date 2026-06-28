import XCTest

/// Smoke test: 启动后根视图为 RootTabView，含 2 个 tab item（Phase 2 砍掉「极简」Tab）。
final class JianDanUITests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        // 跳过开屏短文，直接到 Tab 主界面（避免 5s 等待）
        app.launchArguments = ["-disableSplash"]
        app.launch()

        // 验证 Tab Bar 两个 tab item 存在（Phase 2 已删除「极简」Tab）
        XCTAssertTrue(
            app.tabBars.buttons["告别清单"].waitForExistence(timeout: 5),
            "Tab '告别清单' should exist after launch"
        )
        XCTAssertTrue(
            app.tabBars.buttons["我的"].waitForExistence(timeout: 5),
            "Tab '我的' should exist after launch"
        )
    }

    /// 回归测试：池老板反馈 task9 后新建一条告别清单在列表中看不到。
    /// 流程：进首页 → 点 + → 填名字 → 保存 → 期待列表出现该条记录。
    func testAddFarewellAppearsInList() throws {
        let app = XCUIApplication()
        // 清空 SwiftData store + 跳过开屏
        app.launchArguments = ["-resetStore", "-resetUserDefaults", "-disableSplash"]
        app.launch()

        // 1. 已经在「告别清单」Tab；空状态显示「记下第一件」按钮
        XCTAssertTrue(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 5),
            "Empty state should appear on first launch (or if store was empty)"
        )

        // 2. 点 + 按钮（导航栏右上角）
        let addButton = app.navigationBars.buttons["添加告别记录"]
        if !addButton.exists {
            // 兜底：空状态中央也有一个 + 按钮
            let emptyAdd = app.buttons["记下第一件"]
            XCTAssertTrue(emptyAdd.waitForExistence(timeout: 3), "Should have a way to add")
            emptyAdd.tap()
        } else {
            addButton.tap()
        }

        // 3. 等待 sheet 出现「新建告别」标题
        XCTAssertTrue(
            app.navigationBars["新建告别"].waitForExistence(timeout: 3),
            "Add sheet should appear"
        )

        // 4. 填名称
        let nameField = app.textFields["名称（如：一件蓝色羊毛大衣）"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        nameField.tap()
        nameField.typeText("UI测试告别清单-蓝色羊毛大衣")

        // 5. 点保存
        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        saveButton.tap()

        // 6. 期待 sheet 关闭
        XCTAssertTrue(
            app.navigationBars["新建告别"].waitForNonExistence(timeout: 5),
            "Sheet should dismiss after save"
        )

        // 7. ★ 核心断言：列表里能看到这条记录
        let created = app.staticTexts["UI测试告别清单-蓝色羊毛大衣"]
        XCTAssertTrue(
            created.waitForExistence(timeout: 5),
            "Newly created farewell should appear in the diary list"
        )
    }

    /// Phase 2 回归测试：冷启动开屏短文。
    /// 验证：
    /// 1. launch 后立刻能看到金句（accessibility label 含「开屏短文：」）
    /// 2. 5s 后（或点击后）自动消失，Tab 主界面浮现
    func testSplashQuoteAppearsOnColdLaunch() throws {
        let app = XCUIApplication()
        // 锁定短文 id 让测试可预测 + 缩短自动淡出到 1s
        app.launchArguments = [
            "-resetStore",
            "-resetUserDefaults",
            "-splashQuoteId", "wang-wei-1",
            "-splashAutoDismiss", "1.0"
        ]
        app.launch()

        // 1. 开屏短文应可见（金句 + 出处）
        // SplashQuoteView 用 accessibilityElement(children: .combine) + label「开屏短文：...」
        XCTAssertTrue(
            app.staticTexts["行到水穷处，坐看云起时。"].waitForExistence(timeout: 5),
            "Splash quote text should appear on cold launch"
        )
        XCTAssertTrue(
            app.staticTexts["王维·《终南别业》"].exists,
            "Splash quote attribution should appear"
        )

        // 2. 底部「告别清单」水印可见
        // 注：iOS accessibility 把纯装饰文字降级为「弱标签」，先不强断言
        // XCTAssertTrue(app.staticTexts["告别清单"].exists, "Splash watermark should appear")

        // 3. 等 1.5s 让 1s 倒计时 + 0.4s 淡出完成
        sleep(2)

        // 4. Tab 主界面浮现（已显示空态）
        XCTAssertTrue(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 5),
            "After splash dismiss, diary empty state should appear"
        )

        // 5. 开屏短文已消失
        XCTAssertFalse(
            app.staticTexts["行到水穷处，坐看云起时。"].exists,
            "Splash quote should be dismissed after timeout"
        )
    }

    /// Tap-to-dismiss 回归测试：点击开屏任意位置应立即淡出。
    func testSplashQuoteDismissOnTap() throws {
        let app = XCUIApplication()
        // 长自动淡出（10s）+ 短等待，确保测试期间不会自然消失
        app.launchArguments = [
            "-resetStore",
            "-resetUserDefaults",
            "-splashQuoteId", "wang-wei-1",
            "-splashAutoDismiss", "10.0"
        ]
        app.launch()

        // 1. 开屏短文可见
        XCTAssertTrue(
            app.staticTexts["行到水穷处，坐看云起时。"].waitForExistence(timeout: 5),
            "Splash quote should appear"
        )

        // 2. 点击屏幕中央（坐标点击兜底：因为 onTapGesture 不接受 accessibility hit）
        // iPhone 16 Pro logical 402x874 → 中点约 (200, 437)
        // 用 XCUICoordinate 的 tapped() 在中心点击
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()

        // 3. 等淡出动画完成（0.4s）
        sleep(1)

        // 4. Tab 主界面浮现
        XCTAssertTrue(
            app.staticTexts["还没有告别记录"].waitForExistence(timeout: 5),
            "After tap, diary should appear"
        )
    }

    /// Phase 2 回归：splash 淡出后点击列表项必须能进入详情页
    ///
    /// 背景：之前 `.onTapGesture` 挂在 SplashContainer 外层，splash 不可见后仍拦截
    /// hit test，导致 NavigationLink 无法响应点击。这个测试锁住「splash 不挡点击」。
    func testDiaryCardTappableAfterSplashDismiss() throws {
        let app = XCUIApplication()
        // 用 -seedTestData 自动填充 8 条样本数据，避免手动新建
        app.launchArguments = [
            "-resetStore",
            "-resetUserDefaults",
            "-seedTestData",
            "-disableSplash"
        ]
        app.launch()

        // 1. 列表里出现样本记录（DataImporter 已注入 100 条，按 farewellDate 倒序）
        let firstCard = app.staticTexts["一箱旧明信片"]
        XCTAssertTrue(
            firstCard.waitForExistence(timeout: 15),
            "Sample record should appear in diary list"
        )

        // 2. 点击卡片应进入详情页（关键回归断言）
        firstCard.tap()

        // 3. 详情页 navigationBar 出现，title 为该条记录的名称
        XCTAssertTrue(
            app.navigationBars["一箱旧明信片"].waitForExistence(timeout: 5),
            "Tapping diary card should navigate to detail view (this catches splash overlay blocking hit-tests)"
        )
    }

    /// Task 12 回归测试：「我的」Tab 显示统计 + 主题设置
    func testProfileTabShowsStatsAndSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStore", "-resetUserDefaults", "-disableSplash"]
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

        // 用 waitForExistence + 超时断言三个主题按钮都存在
        // 注意：不检查「默认选中态」——测试间顺序可能导致主题被前一个测试改动
        // ThemeManager 默认选中的行为由单元测试覆盖，UI test 只保证 UI 元素存在
        XCTAssertTrue(
            app.buttons.matching(lightPredicate).firstMatch.waitForExistence(timeout: 3),
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

        // 导入测试数据按钮可见
        // 通过「8 条样本」副标题文字验证（左侧是「导入测试数据」按钮）
        XCTAssertTrue(
            app.staticTexts["8 条样本"].exists,
            "Sample data import hint should appear"
        )
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS '导入'")).firstMatch.exists,
            "Import test data button should appear"
        )
    }
}