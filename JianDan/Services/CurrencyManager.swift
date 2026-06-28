import Foundation
import Observation

/// 币种偏好管理：使用 UserDefaults 持久化
///
/// iOS 17+ 使用 `@Observable` 而非 `ObservableObject`，与 `ThemeManager` 风格一致。
@Observable
final class CurrencyManager {
    private let key = "app.currency"

    var currency: Currency {
        didSet {
            UserDefaults.standard.set(currency.rawValue, forKey: key)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let saved = Currency(rawValue: raw) {
            self.currency = saved
        } else {
            self.currency = .cny
        }
    }
}