import Foundation
import SwiftUI

/// 主题偏好管理：使用 UserDefaults 持久化
///
/// iOS 17+ 使用 `@Observable` 而非 `ObservableObject`，与 SwiftUI 配合更自然。
@Observable
final class ThemeManager {
    private let key = "app.themeMode"

    var mode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: key)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let saved = AppThemeMode(rawValue: raw) {
            self.mode = saved
        } else {
            self.mode = .light
        }
    }
}
