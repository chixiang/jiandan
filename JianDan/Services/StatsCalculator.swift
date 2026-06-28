import Foundation

/// 告别统计结果（纯值类型，便于测试与缓存）
struct FarewellStats: Equatable {
    let totalCount: Int
    let averageCompanionshipDays: Int?
    let longestCompanionshipDays: Int
    let totalPurchasePrice: Double
    let categoryBreakdown: [CategoryCount]
    let categoryPriceBreakdown: [CategoryPriceCount]
    let methodBreakdown: [MethodCount]
    let emotionBreakdown: [EmotionCount]

    var isEmpty: Bool {
        totalCount == 0
    }
}

struct CategoryCount: Equatable, Hashable {
    let category: AnyCategory
    let count: Int
}

struct CategoryPriceCount: Equatable {
    let category: AnyCategory
    let totalPrice: Double
}

struct MethodCount: Equatable {
    let name: String
    let icon: String
    let count: Int
}

struct EmotionCount: Equatable {
    let stars: Int
    let name: String
    let count: Int
}

enum StatsCalculator {
    static func compute(
        from records: [FarewellRecord]
    ) -> FarewellStats {
        let totalCount = records.count

        let companionshipValues = records.compactMap { $0.companionshipDays }
        let totalCompanionshipDaysSum = companionshipValues.reduce(0, +)
        let averageCompanionshipDays: Int? = companionshipValues.isEmpty
            ? nil
            : Int((Double(totalCompanionshipDaysSum) / Double(companionshipValues.count)).rounded())
        let longestCompanionshipDays = companionshipValues.max() ?? 0

        let totalPurchasePrice = records.compactMap { $0.purchasePrice }.reduce(0, +)

        var categoryMap: [AnyCategory: Int] = [:]
        var categoryPriceMap: [AnyCategory: Double] = [:]
        for record in records {
            categoryMap[record.category, default: 0] += 1
            categoryPriceMap[record.category, default: 0] += record.purchasePrice ?? 0
        }
        let categoryBreakdown = categoryMap
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        let categoryPriceBreakdown = categoryPriceMap
            .filter { $0.value > 0 }
            .map { CategoryPriceCount(category: $0.key, totalPrice: $0.value) }
            .sorted { $0.totalPrice > $1.totalPrice }

        var methodCounts: [String: Int] = [:]
        for record in records {
            methodCounts[record.methodRaw, default: 0] += 1
        }
        let methodBreakdown = FarewellMethod.allCases
            .compactMap { method -> MethodCount? in
                guard let count = methodCounts[method.rawValue], count > 0 else { return nil }
                return MethodCount(name: method.localizedName, icon: method.icon, count: count)
            }
            .sorted { $0.count > $1.count }

        var emotionCounts: [Int: Int] = [:]
        for record in records {
            if let ev = record.emotionValue {
                emotionCounts[ev, default: 0] += 1
            }
        }
        let emotionLabels: [Int: String] = [
            1: String(localized: "平静"),
            2: String(localized: "复杂"),
            3: String(localized: "不舍")
        ]
        let emotionBreakdown = (1...3).map { stars in
            EmotionCount(
                stars: stars,
                name: emotionLabels[stars] ?? "",
                count: emotionCounts[stars] ?? 0
            )
        }.sorted { $0.count > $1.count }

        return FarewellStats(
            totalCount: totalCount,
            averageCompanionshipDays: averageCompanionshipDays,
            longestCompanionshipDays: longestCompanionshipDays,
            totalPurchasePrice: totalPurchasePrice,
            categoryBreakdown: categoryBreakdown,
            categoryPriceBreakdown: categoryPriceBreakdown,
            methodBreakdown: methodBreakdown,
            emotionBreakdown: Array(emotionBreakdown)
        )
    }
}
