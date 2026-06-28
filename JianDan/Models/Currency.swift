import Foundation

/// 币种选择
///
/// 币种仅影响价格显示（符号 + 图标），不影响存储 — `FarewellRecord.purchasePrice` 仍是无单位的 `Double`。
/// CNY 和 JPY 都使用 `¥` 符号和 `yensign` SF Symbol，SF Symbols 未提供区分两者的图标。
enum Currency: String, CaseIterable, Identifiable, Codable {
    case cny = "CNY"
    case usd = "USD"
    case eur = "EUR"
    case jpy = "JPY"
    case gbp = "GBP"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cny: return String(localized: "人民币")
        case .usd: return String(localized: "美元")
        case .eur: return String(localized: "欧元")
        case .jpy: return String(localized: "日元")
        case .gbp: return String(localized: "英镑")
        }
    }

    var symbol: String {
        switch self {
        case .cny, .jpy: return "¥"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }

    /// SF Symbol name（裸符号，pill 风格使用）
    var icon: String {
        switch self {
        case .cny: return "yensign"
        case .jpy: return "yensign"
        case .usd: return "dollarsign"
        case .eur: return "eurosign"
        case .gbp: return "sterlingsign"
        }
    }

    /// SF Symbol name（带 .circle 后缀，统计卡片风格使用）
    var iconCircle: String {
        switch self {
        case .cny, .jpy: return "yensign.circle"
        case .usd: return "dollarsign.circle"
        case .eur: return "eurosign.circle"
        case .gbp: return "sterlingsign.circle"
        }
    }
}