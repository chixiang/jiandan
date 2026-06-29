import Foundation

/// 短文仓库：从 `daily_quotes.json` 加载每日一句与全量列表
///
/// 设计要点：
/// - JSON 资源位于 `JianDan/Resources/Quotes/daily_quotes.json`
/// - 「今日一句」算法：`dayOfYear % quotes.count`，无需 UserDefaults
///   - 优点：跨设备一致，无需写入；同一日所有用户看到同一句
///   - 缺点：用户无法锁定喜欢的句子（Phase 2 可加「收藏」）
/// - 容错：JSON 缺失/解析失败时返回空数组（UI 显示空态），不抛错
final class QuoteRepository {
    /// JSON 文件名（无后缀）
    static let jsonResourceName = "daily_quotes"
    /// JSON 文件扩展名
    static let jsonResourceExtension = "json"

    /// 短文缓存（首次访问时加载）
    private var cachedQuotes: [Wisdom]?

    /// 全量短文（按 JSON 顺序）
    var all: [Wisdom] {
        if let cached = cachedQuotes {
            return cached
        }
        let loaded = loadQuotes()
        cachedQuotes = loaded
        return loaded
    }

    /// 今日一句：基于「年内的第几天」做哈希选择
    /// - Parameter date: 用于计算的日期（默认今天，便于测试注入）
    /// - Returns: 当日短文；若库为空则返回 nil
    func todayQuote(for date: Date = .now, calendar: Calendar = .current) -> Wisdom? {
        let quotes = all
        guard !quotes.isEmpty else { return nil }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        // 用 dayOfYear - 1 作为下标（年初首日 = 第 1 天 → index 0）
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }

    /// 冷启动随机一句：每次调用随机选一条（无放回机制，纯粹随机）
    /// - Parameter randomSource: 随机源（默认系统 `Random`，测试可注入 `RandomStub`）
    /// - Returns: 随机短文；若库为空则返回 nil
    func randomQuote(using randomSource: inout RandomSource) -> Wisdom? {
        let quotes = all
        guard !quotes.isEmpty else { return nil }
        let index = randomSource.nextInt(upperBound: quotes.count)
        return quotes[index]
    }

    /// 无参便捷重载：使用系统随机源（生产环境调用此方法）
    func randomQuote() -> Wisdom? {
        var source: RandomSource = SystemRandomSource()
        return randomQuote(using: &source)
    }

    // MARK: - Private

    /// 从 bundle 加载 JSON 并解析为 [Wisdom]
    /// 容错策略：
    /// - 文件不存在 / 解析失败 → 返回 []
    /// - 单条 quote 字段缺失 → 跳过该条，不抛错
    /// - quote 字段非法（如 text 为空）→ 跳过该条
    private func loadQuotes() -> [Wisdom] {
        guard let url = Bundle.main.url(
            forResource: Self.jsonResourceName,
            withExtension: Self.jsonResourceExtension
        ) else {
            print("[QuoteRepository] JSON file not found in bundle: \(Self.jsonResourceName).\(Self.jsonResourceExtension)")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let payload = try decoder.decode(QuotePayload.self, from: data)
            return payload.quotes.compactMap { entry in
                guard !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !entry.attribution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return nil
                }
                // Wisdom.init 用 precondition；JSON 端已清洗到非空字段
                // 长度上限由 JSON 作者保证（仓库信任内置资源）
                return Wisdom(
                    id: entry.id,
                    text: entry.text,
                    attribution: entry.attribution,
                    category: entry.category,
                    textEn: entry.textEn,
                    attributionEn: entry.attributionEn,
                    textJa: entry.textJa,
                    attributionJa: entry.attributionJa
                )
            }
        } catch {
            print("[QuoteRepository] Failed to decode JSON: \(error)")
            return []
        }
    }
}

// MARK: - JSON Schema

/// JSON 顶层结构：version + quotes 数组
private struct QuotePayload: Decodable {
    let version: Int
    let quotes: [QuoteEntry]
}

/// JSON 单条 entry
private struct QuoteEntry: Decodable {
    let id: String
    let text: String
    let attribution: String
    let category: String?
    let textEn: String?
    let attributionEn: String?
    let textJa: String?
    let attributionJa: String?
}