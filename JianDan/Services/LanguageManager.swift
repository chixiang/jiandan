import Foundation
import Observation

/// 语言偏好管理：使用 UserDefaults 持久化 + AppleLanguages 覆写
///
/// 语言切换通过修改 `AppleLanguages` UserDefaults key 实现，该 key
/// 在进程启动时由 Foundation 读取，因此切换后需要重启 app 才能生效。
/// 重启后 app 会从 `UserDefaults.standard.string(forKey:)` 恢复上次选择。
@Observable
final class LanguageManager {
    private let key = "app.language"

    var language: AppLanguage {
        didSet {
            persist()
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let saved = AppLanguage(rawValue: raw) {
            self.language = saved
        } else {
            self.language = .system
        }
        applyToUserDefaults()
    }

    /// 切换语言 — 写入 UserDefaults + AppleLanguages（重启后生效）
    func apply(_ newLanguage: AppLanguage) {
        language = newLanguage
    }

    private func persist() {
        UserDefaults.standard.set(language.rawValue, forKey: key)
        applyToUserDefaults()
    }

    private func applyToUserDefaults() {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
    }
}
