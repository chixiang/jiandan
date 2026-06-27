import XCTest
@testable import JianDan

/// `ThemeManager` 全面测试
///
/// 覆盖：默认态、UserDefaults 损坏回退、didSet 写入、跨实例持久化、所有 theme mode round-trip
@MainActor
final class ThemeManagerTests: XCTestCase {

    private let key = "app.themeMode"

    override func setUp() {
        super.setUp()
        // 每个测试前清理 UserDefaults 中的 theme 键
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    // MARK: - 默认态

    func testDefaultModeIsLightWhenUserDefaultsEmpty() {
        UserDefaults.standard.removeObject(forKey: key)
        let manager = ThemeManager()
        XCTAssertEqual(manager.mode, .light)
    }

    func testCorruptedUserDefaultsValueFallsBackToLight() {
        // 写入一个无法解析的字符串，ThemeManager 应回退到 light
        UserDefaults.standard.set("not-a-valid-mode", forKey: key)
        let manager = ThemeManager()
        XCTAssertEqual(manager.mode, .light)
    }

    // MARK: - didSet 写入

    func testDidSetWritesImmediately() {
        let manager = ThemeManager()
        manager.mode = .ink
        // 同步写入（didSet 在赋值时立即执行）
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "墨色")
    }

    func testDidSetWritesAllThemeModes() {
        for mode in AppThemeMode.allCases {
            let manager = ThemeManager()
            manager.mode = mode
            XCTAssertEqual(UserDefaults.standard.string(forKey: key), mode.rawValue)
        }
    }

    // MARK: - 持久化

    func testPersistsAcrossInstances() {
        let writer = ThemeManager()
        writer.mode = .dark

        let reader = ThemeManager()
        XCTAssertEqual(reader.mode, .dark)
    }

    func testAllThemeModesRoundTripViaUserDefaults() {
        for mode in AppThemeMode.allCases {
            // 写入
            UserDefaults.standard.set(mode.rawValue, forKey: key)
            // 读取
            let manager = ThemeManager()
            XCTAssertEqual(manager.mode, mode, "Mode \(mode.rawValue) should round-trip")
        }
    }

    // MARK: - 修改不影响其他状态

    func testModeChangeIsObservableViaNewInstance() {
        let first = ThemeManager()
        first.mode = .ink

        // 即便不重启，新实例也应该读到最新的值
        let second = ThemeManager()
        XCTAssertEqual(second.mode, .ink)
    }
}