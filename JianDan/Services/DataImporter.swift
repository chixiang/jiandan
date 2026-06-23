import Foundation
import SwiftData

/// 数据导入服务：从内置 JSON 加载测试数据到 SwiftData
///
/// 设计要点：
/// - 幂等：每次导入都生成新 UUID，不会覆盖已有数据
/// - 防重复：用「名称 + 告别日期」去重检查（同一日期同一物品不重复导入）
/// - 安全：运行在主线程上（SwiftData MainContext）
/// - 反馈：返回导入结果统计
final class DataImporter {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// 从内置 JSON 导入样本记录
    /// - Parameter jsonData: 可选——提供此参数则跳过 bundle 加载（测试用）；nil 时从 app bundle 加载
    /// - Returns: 导入统计
    @discardableResult
    func importSampleRecords(jsonData: Data? = nil) -> ImportResult {
        let data: Data
        if let provided = jsonData {
            data = provided
        } else {
            guard let url = Bundle.main.url(
                forResource: "sample_records",
                withExtension: "json"
            ) else {
                return ImportResult(imported: 0, skipped: 0, error: "JSON file not found in bundle")
            }
            do {
                data = try Data(contentsOf: url)
            } catch {
                return ImportResult(imported: 0, skipped: 0, error: error.localizedDescription)
            }
        }

        do {
            let decoder = JSONDecoder()
            // JSON 采用 date-only 格式 "yyyy-MM-dd"，非完整 ISO8601 带时间
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let payload = try decoder.decode(SampleRecordsPayload.self, from: data)

            var imported = 0
            var skipped = 0

            for dto in payload.records {
                // 去重检查：名称 + 告别日期 → 内存过滤（#Predicate 不支持跨类型比较）
                let descriptor = FetchDescriptor<FarewellRecord>()
                let all = try context.fetch(descriptor)
                let isDuplicate = all.contains { $0.name == dto.name && $0.farewellDate == dto.farewellDate }
                if isDuplicate {
                    skipped += 1
                    continue
                }

                let record = FarewellRecord(
                    name: dto.name,
                    category: Category(rawValue: dto.category) ?? .other,
                    farewellDate: dto.farewellDate,
                    method: FarewellMethod(rawValue: dto.method) ?? .other,
                    purchaseDate: dto.purchaseDate,
                    recipientDetail: dto.recipientDetail,
                    purchasePrice: dto.purchasePrice,
                    emotionValue: dto.emotionValue,
                    farewellLetter: dto.farewellLetter,
                    photoFilenames: []
                )
                context.insert(record)
                imported += 1
            }

            try context.save()
            return ImportResult(imported: imported, skipped: skipped, error: nil)

        } catch {
            return ImportResult(imported: 0, skipped: 0, error: error.localizedDescription)
        }
    }

    /// 导入结果
    struct ImportResult: Equatable {
        let imported: Int
        let skipped: Int
        let error: String?

        var isSuccess: Bool { error == nil }
        var totalFound: Int { imported + skipped }
    }

    /// 仅用于清空 store 后的「一键填充分装」——与 -seedTestData launch arg 配合
    /// 返回所有已导入记录的统计摘要
    var importSummary: String {
        let result = importSampleRecords()
        if let err = result.error {
            return "导入失败：\(err)"
        }
        return "已导入 \(result.imported) 条，跳过 \(result.skipped) 条（重复）"
    }
}

// MARK: - JSON 解码结构

/// JSON 顶层结构
private struct SampleRecordsPayload: Decodable {
    let version: Int
    let records: [SampleRecordDTO]
}

/// 单条记录 DTO（镜像 FarewellRecord 字段，纯值类型便于解码）
private struct SampleRecordDTO: Decodable {
    let name: String
    let category: String
    let farewellDate: Date
    let method: String
    let purchaseDate: Date?
    let purchasePrice: Double?
    let emotionValue: Int?
    let recipientDetail: String?
    let farewellLetter: String?
    let photoFilenames: [String]
}