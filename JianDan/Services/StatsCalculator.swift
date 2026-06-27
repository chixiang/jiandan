import Foundation

/// 告别统计结果（纯值类型，便于测试与缓存）
///
/// 由 `StatsCalculator` 从 `[FarewellRecord]` 计算得出。
/// 任何字段为 0 / 空时仍返回合法结构，由 UI 决定如何呈现「空态」。
struct FarewellStats: Equatable {
    /// 告别总数
    let totalCount: Int
    /// 平均陪伴天数（仅统计有购入日期的记录；无记录或全无购入日期则为 nil）
    let averageCompanionshipDays: Double?
    /// 最久陪伴天数
    let longestCompanionshipDays: Int
    /// 购入总价（仅统计有 price 的记录）
    let totalPurchasePrice: Double
    /// 分类分布：按数量降序
    let categoryBreakdown: [CategoryCount]
    /// 情感均值（1...5，所有有 emotionValue 的记录的平均；无记录则 nil）
    let averageEmotion: Double?
    /// 最常去向（告别方式中出现次数最多的；无记录则 nil）
    let topMethod: TopMethodInfo?

    /// 是否完全为空（所有指标都为 0 / 空）
    var isEmpty: Bool {
        totalCount == 0
    }
}

/// 最常去向信息
struct TopMethodInfo: Equatable {
    let name: String
    let count: Int
}

/// 分类计数（用于分类分布列表）
/// 拆出独立 struct 是为了让 `FarewellStats` 可自动合成 Equatable（Swift 元组数组不支持 Equatable）。
struct CategoryCount: Equatable, Hashable {
    let category: AnyCategory
    let count: Int
}

/// 统计计算器：纯函数式，无副作用，便于单元测试
enum StatsCalculator {
    /// 计算一组记录的累计统计数据
    static func compute(
        from records: [FarewellRecord]
    ) -> FarewellStats {
        let totalCount = records.count

        let companionshipValues = records.compactMap { $0.companionshipDays }
        let totalCompanionshipDaysSum = companionshipValues.reduce(0, +)
        let averageCompanionshipDays: Double? = companionshipValues.isEmpty
            ? nil
            : Double(totalCompanionshipDaysSum) / Double(companionshipValues.count)
        let longestCompanionshipDays = companionshipValues.max() ?? 0

        let totalPurchasePrice = records.compactMap { $0.purchasePrice }.reduce(0, +)

        var categoryMap: [AnyCategory: Int] = [:]
        for record in records {
            categoryMap[record.category, default: 0] += 1
        }
        let categoryBreakdown = categoryMap
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        let emotionValues = records.compactMap { $0.emotionValue }
        let averageEmotion: Double? = emotionValues.isEmpty
            ? nil
            : Double(emotionValues.reduce(0, +)) / Double(emotionValues.count)

        var methodCounts: [String: Int] = [:]
        for record in records {
            methodCounts[record.methodRaw, default: 0] += 1
        }
        let topMethod: TopMethodInfo? = methodCounts
            .max { $0.value < $1.value }
            .map { TopMethodInfo(name: $0.key, count: $0.value) }

        return FarewellStats(
            totalCount: totalCount,
            averageCompanionshipDays: averageCompanionshipDays,
            longestCompanionshipDays: longestCompanionshipDays,
            totalPurchasePrice: totalPurchasePrice,
            categoryBreakdown: categoryBreakdown,
            averageEmotion: averageEmotion,
            topMethod: topMethod
        )
    }
}
