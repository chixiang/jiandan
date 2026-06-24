import Foundation

/// 年月（用于按月切片的标识，不含日期）
///
/// 仅统计粒度，不承载时区敏感语义——以用户当地日历为准。
struct YearMonth: Equatable, Hashable, Comparable {
    let year: Int
    let month: Int  // 1...12

    static func current(referenceDate: Date = .now, calendar: Calendar = .current) -> YearMonth {
        let comps = calendar.dateComponents([.year, .month], from: referenceDate)
        return YearMonth(year: comps.year ?? 1970, month: comps.month ?? 1)
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        return lhs.month < rhs.month
    }
}

/// 统计范围
///
/// - `.allTime` —— 全期累计（默认）
/// - `.month(ym)` —— 仅看指定年月的告别
enum StatsScope: Equatable {
    case allTime
    case month(YearMonth)
}

/// 告别统计结果（纯值类型，便于测试与缓存）
///
/// 由 `StatsCalculator` 从 `[FarewellRecord]` 计算得出。
/// 任何字段为 0 / 空时仍返回合法结构，由 UI 决定如何呈现「空态」。
struct FarewellStats: Equatable {
    /// 告别总数（当前 scope 内）
    let totalCount: Int
    /// 陪伴总天数（仅统计有购入日期的记录）
    let totalCompanionshipDays: Int
    /// 最久陪伴天数
    let longestCompanionshipDays: Int
    /// 购入总价（仅统计有 price 的记录）
    let totalPurchasePrice: Double
    /// 分类分布：按数量降序
    let categoryBreakdown: [CategoryCount]
    /// 情感均值（1...5，所有有 emotionValue 的记录的平均；无记录则 nil）
    let averageEmotion: Double?
    /// 当前 scope 的展示标题
    /// - nil：累计态（UI 不显示副标题）
    /// - 非 nil：例如 "2026 年 6 月"
    let monthLabel: String?

    /// 是否完全为空（所有指标都为 0 / 空）
    var isEmpty: Bool {
        totalCount == 0
    }
}

/// 分类计数（用于分类分布列表）
/// 拆出独立 struct 是为了让 `FarewellStats` 可自动合成 Equatable（Swift 元组数组不支持 Equatable）。
struct CategoryCount: Equatable, Hashable {
    let category: AnyCategory
    let count: Int
}

/// 统计计算器：纯函数式，无副作用，便于单元测试
enum StatsCalculator {
    /// 计算一组记录在指定 scope 下的统计数据
    /// - Parameters:
    ///   - records: 待统计的 FarewellRecord 列表
    ///   - scope: 统计范围（默认 `.allTime`）
    ///   - calendar: 日期计算所用日历（默认 .current，便于测试注入）
    ///   - referenceDate: 「本月」判定参考日期（默认 .now）
    static func compute(
        from records: [FarewellRecord],
        scope: StatsScope = .allTime,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> FarewellStats {
        // 1. 按 scope 过滤
        let filtered = records.filter { record in
            switch scope {
            case .allTime:
                return true
            case .month(let ym):
                let comps = calendar.dateComponents([.year, .month], from: record.farewellDate)
                guard let y = comps.year, let m = comps.month else { return false }
                return y == ym.year && m == ym.month
            }
        }

        let totalCount = filtered.count

        // 2. 陪伴天数（仅统计有购入日期的）
        let companionshipValues = filtered.compactMap { $0.companionshipDays }
        let totalCompanionshipDays = companionshipValues.reduce(0, +)
        let longestCompanionshipDays = companionshipValues.max() ?? 0

        // 3. 总价
        let totalPurchasePrice = filtered.compactMap { $0.purchasePrice }.reduce(0, +)

        // 4. 分类分布
        var categoryMap: [AnyCategory: Int] = [:]
        for record in filtered {
            categoryMap[record.category, default: 0] += 1
        }
        let categoryBreakdown = categoryMap
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // 5. 情感均值
        let emotionValues = filtered.compactMap { $0.emotionValue }
        let averageEmotion: Double? = emotionValues.isEmpty
            ? nil
            : Double(emotionValues.reduce(0, +)) / Double(emotionValues.count)

        // 6. 标题
        let monthLabel: String?
        switch scope {
        case .allTime:
            monthLabel = nil
        case .month(let ym):
            monthLabel = "\(ym.year) 年 \(ym.month) 月"
        }

        return FarewellStats(
            totalCount: totalCount,
            totalCompanionshipDays: totalCompanionshipDays,
            longestCompanionshipDays: longestCompanionshipDays,
            totalPurchasePrice: totalPurchasePrice,
            categoryBreakdown: categoryBreakdown,
            averageEmotion: averageEmotion,
            monthLabel: monthLabel
        )
    }

    /// 从记录中提取有数据的所有月份（按时间倒序：最新 → 最旧）
    ///
    /// 用于 ProfileView 渲染月份切换器。仅展示有告别记录的月份。
    static func monthsWithRecords(
        in records: [FarewellRecord],
        calendar: Calendar = .current
    ) -> [YearMonth] {
        var seen: Set<YearMonth> = []
        for record in records {
            let comps = calendar.dateComponents([.year, .month], from: record.farewellDate)
            guard let y = comps.year, let m = comps.month else { continue }
            seen.insert(YearMonth(year: y, month: m))
        }
        return seen.sorted(by: >)  // 倒序：最新在前
    }
}