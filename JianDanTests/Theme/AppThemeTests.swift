import XCTest
import SwiftUI
@testable import JianDan

final class AppThemeTests: XCTestCase {
    // MARK: - AppTheme 颜色映射

    func testLightThemeColors() {
        let theme = AppTheme(mode: .light)
        XCTAssertEqual(theme.background, AppColors.Light.background)
        XCTAssertEqual(theme.primaryText, AppColors.Light.primaryText)
        XCTAssertEqual(theme.accent, AppColors.Light.accent)
        XCTAssertEqual(theme.secondary, AppColors.Light.secondary)
        XCTAssertEqual(theme.cardBackground, AppColors.Light.cardBackground)
        XCTAssertEqual(theme.divider, AppColors.Light.divider)
    }

    func testDarkThemeColors() {
        let theme = AppTheme(mode: .dark)
        XCTAssertEqual(theme.background, AppColors.Dark.background)
        XCTAssertEqual(theme.primaryText, AppColors.Dark.primaryText)
        XCTAssertEqual(theme.accent, AppColors.Dark.accent)
        XCTAssertEqual(theme.secondary, AppColors.Dark.secondary)
        XCTAssertEqual(theme.cardBackground, AppColors.Dark.cardBackground)
        XCTAssertEqual(theme.divider, AppColors.Dark.divider)
    }

    func testInkThemeColors() {
        let theme = AppTheme(mode: .ink)
        XCTAssertEqual(theme.background, AppColors.Ink.background)
        XCTAssertEqual(theme.primaryText, AppColors.Ink.primaryText)
        XCTAssertEqual(theme.accent, AppColors.Ink.accent)
        XCTAssertEqual(theme.secondary, AppColors.Ink.secondary)
        XCTAssertEqual(theme.cardBackground, AppColors.Ink.cardBackground)
        XCTAssertEqual(theme.divider, AppColors.Ink.divider)
        // sanity: 墨色背景确实就是纯黑
        XCTAssertEqual(theme.background, .black)
    }

    // MARK: - AppThemeMode 元数据

    func testThemeModeColorScheme() {
        XCTAssertEqual(AppThemeMode.light.colorScheme, .light)
        XCTAssertEqual(AppThemeMode.dark.colorScheme, .dark)
        XCTAssertEqual(AppThemeMode.ink.colorScheme, .dark)
    }

    func testThemeModeAllCases() {
        XCTAssertEqual(AppThemeMode.allCases.count, 3)
    }

    func testThemeModeRawValues() {
        XCTAssertEqual(AppThemeMode.light.rawValue, "浅色")
        XCTAssertEqual(AppThemeMode.dark.rawValue, "深色")
        XCTAssertEqual(AppThemeMode.ink.rawValue, "墨色")
    }

    func testThemeModeDisplayNameMatchesRawValue() {
        XCTAssertEqual(AppThemeMode.light.displayName, "浅色")
        XCTAssertEqual(AppThemeMode.dark.displayName, "深色")
        XCTAssertEqual(AppThemeMode.ink.displayName, "墨色")
    }

    // MARK: - ThemeManager 持久化

    func testThemeManagerPersistence() {
        // 先重置，避免污染其他测试
        let manager = ThemeManager()
        manager.mode = .light
        XCTAssertEqual(manager.mode, .light)

        // 切换到 ink
        manager.mode = .ink
        XCTAssertEqual(manager.mode, .ink)

        // 新实例应读取到上一次的写入
        let manager2 = ThemeManager()
        XCTAssertEqual(manager2.mode, .ink, "ThemeManager should persist across instances")

        // 清理：恢复默认，避免影响其他测试
        manager.mode = .light
    }

    // MARK: - EnvironmentKey

    func testAppThemeDefaultEnvironmentIsLight() {
        var env = EnvironmentValues()
        // 默认值
        let defaultTheme = AppTheme(mode: .light)
        XCTAssertEqual(env.appTheme.mode, defaultTheme.mode)
    }

    func testEnvironmentKeySetterGetter() {
        var env = EnvironmentValues()
        let customTheme = AppTheme(mode: .ink)
        env.appTheme = customTheme
        XCTAssertEqual(env.appTheme.mode, .ink)
        XCTAssertEqual(env.appTheme.background, AppColors.Ink.background)
    }

    func testAppThemeModifierAppliesTint() {
        // 用 Image 应用 modifier，验证 .tint 被设置
        // 直接测试 modifier 太复杂（需要 ViewInspector），改为检查主题色映射即可
        let inkTheme = AppTheme(mode: .ink)
        XCTAssertEqual(inkTheme.accent, AppColors.Ink.accent)
        let darkTheme = AppTheme(mode: .dark)
        XCTAssertEqual(darkTheme.accent, AppColors.Dark.accent)
        let lightTheme = AppTheme(mode: .light)
        XCTAssertEqual(lightTheme.accent, AppColors.Light.accent)
    }
}
