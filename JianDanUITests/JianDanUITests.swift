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
}