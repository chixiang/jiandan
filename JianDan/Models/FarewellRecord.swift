import Foundation
import SwiftData

/// 一条告别记录：用户对一件物品的告别存档
@Model
final class FarewellRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var purchaseDate: Date?
    var farewellDate: Date
    var methodRaw: String
    var recipientDetail: String?
    var purchasePrice: Double?
    var emotionValue: Int?
    var farewellLetter: String?
    /// 已存沙盒的图片文件名（UUID.jpg）；实际文件由 ImageStore 管理
    var photoFilenames: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        category: AnyCategory,
        farewellDate: Date = .now,
        method: FarewellMethod,
        purchaseDate: Date? = nil,
        recipientDetail: String? = nil,
        purchasePrice: Double? = nil,
        emotionValue: Int? = nil,
        farewellLetter: String? = nil,
        photoFilenames: [String] = []
    ) {
        // 名称：trim 后非空 + 长度不超过 50
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmedName.isEmpty, "FarewellRecord name cannot be empty")
        precondition(
            trimmedName.count <= Self.nameMaxLength,
            "FarewellRecord name too long (max \(Self.nameMaxLength))"
        )

        // 照片：不超过 maxPhotos
        precondition(photoFilenames.count <= Self.maxPhotos, "Too many photos (max \(Self.maxPhotos))")

        // 告别信：长度不超过 500
        if let letter = farewellLetter {
            precondition(
                letter.count <= Self.farewellLetterMaxLength,
                "Farewell letter too long (max \(Self.farewellLetterMaxLength))"
            )
        }

        // 收件详情：长度不超过 200
        if let detail = recipientDetail {
            precondition(
                detail.count <= Self.recipientDetailMaxLength,
                "recipientDetail too long (max \(Self.recipientDetailMaxLength))"
            )
        }

        // 情感价值：1...5（约定俗成）
        if let value = emotionValue {
            precondition((1...3).contains(value), "emotionValue out of range (1...3)")
        }

        // 购入价：>= 0
        if let price = purchasePrice {
            precondition(price >= 0, "purchasePrice must be non-negative")
        }

        // 购入日期不晚于告别日期
        if let purchase = purchaseDate {
            precondition(
                purchase <= farewellDate,
                "purchaseDate must be on or before farewellDate"
            )
        }

        self.id = UUID()
        self.name = trimmedName
        self.categoryRaw = category.storageID
        self.farewellDate = farewellDate
        self.methodRaw = method.rawValue
        self.purchaseDate = purchaseDate
        self.recipientDetail = recipientDetail
        self.purchasePrice = purchasePrice
        self.emotionValue = emotionValue
        self.farewellLetter = farewellLetter
        self.photoFilenames = photoFilenames
        self.createdAt = .now
        self.updatedAt = .now
    }

    /// 分类便捷访问（解析为 AnyCategory；找不到时 fallback 到 .other）
    var category: AnyCategory {
        AnyCategory.resolve(storageID: categoryRaw)
    }

    /// 分类 ID（AnyCategory.storageID 等价）
    var categoryID: String {
        get { categoryRaw }
        set { categoryRaw = newValue }
    }

    /// 告别方式便捷访问
    var method: FarewellMethod {
        get { FarewellMethod(rawValue: methodRaw) ?? .other }
        set { methodRaw = newValue.rawValue }
    }

    /// 陪伴天数（购入到告别）
    var companionshipDays: Int? {
        guard let purchase = purchaseDate else { return nil }
        return Calendar.current.dateComponents([.day], from: purchase, to: farewellDate).day
    }

    /// 字段长度上限常量（供 UI 校验复用）
    static let farewellLetterMaxLength = 500
    static let nameMaxLength = 50
    static let recipientDetailMaxLength = 200
    static let maxPhotos = 3
}