import Foundation

/// 告别统计结果（纯值类型，便于测试与缓存）
///
/// 由 `StatsCalculator` 从 `[FarewellRecord]` 计算得出。
/// 任何字段为 0 / 空时仍返回合法结构，由 UI 决定如何呈现「空态」。
struct FarewellStats: Equatable {
    /// 告别总数
    let totalCount: Int
    /// 陪伴总天数（仅统计有购入日期的记录）
    let totalCompanionshipDays: Int
    /// 最久陪伴天数
    let longestCompanionshipDays: Int
    /// 本月（自然月）告别数
    let thisMonthCount: Int
    /// 购入总价（仅统计有 price 的记录）
    let totalPurchasePrice: Double
    /// 分类分布：按数量降序
    let categoryBreakdown: [CategoryCount]
    /// 情感均值（1...5，所有有 emotionValue 的记录的平均；无记录则 nil）
    let averageEmotion: Double?

    /// 是否完全为空（所有指标都为 0 / 空）
    var isEmpty: Bool {
        totalCount == 0
    }
}

/// 分类计数（用于分类分布列表）
/// 拆出独立 struct 是为了让 `FarewellStats` 可自动合成 Equatable（Swift 元组数组不支持 Equatable）。
struct CategoryCount: Equatable, Hashable {
    let category: Category
    let count: Int
}

/// 统计计算器：纯函数式，无副作用，便于单元测试
enum StatsCalculator {
    /// 计算一组记录的统计数据
    /// - Parameter records: 待统计的 FarewellRecord 列表
    /// - Parameter calendar: 日期计算所用日历（默认 .current，便于测试注入）
    /// - Parameter referenceDate: 「本月」判定参考日期（默认 .now）
    static func compute(
        from records: [FarewellRecord],
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> FarewellStats {
        let totalCount = records.count

        // 陪伴天数（仅统计有购入日期的）
        let companionshipValues = records.compactMap { $0.companionshipDays }
        let totalCompanionshipDays = companionshipValues.reduce(0, +)
        let longestCompanionshipDays = companionshipValues.max() ?? 0

        // 本月计数
        let thisMonthCount = records.filter { record in
            calendar.isDate(record.farewellDate, equalTo: referenceDate, toGranularity: .month)
        }.count

        // 总价
        let totalPurchasePrice = records.compactMap { $0.purchasePrice }.reduce(0, +)

        // 分类分布
        var categoryMap: [Category: Int] = [:]
        for record in records {
            categoryMap[record.category, default: 0] += 1
        }
        let categoryBreakdown = categoryMap
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // 情感均值
        let emotionValues = records.compactMap { $0.emotionValue }
        let averageEmotion: Double? = emotionValues.isEmpty
            ? nil
            : Double(emotionValues.reduce(0, +)) / Double(emotionValues.count)

        return FarewellStats(
            totalCount: totalCount,
            totalCompanionshipDays: totalCompanionshipDays,
            longestCompanionshipDays: longestCompanionshipDays,
            thisMonthCount: thisMonthCount,
            totalPurchasePrice: totalPurchasePrice,
            categoryBreakdown: categoryBreakdown,
            averageEmotion: averageEmotion
        )
    }
}