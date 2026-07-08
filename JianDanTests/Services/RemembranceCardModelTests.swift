import XCTest
@testable import JianDan

@MainActor
final class RemembranceCardModelTests: XCTestCase {

    /// NOTE: `companionshipDays` on FarewellRecord is a *computed* property derived
    /// from `purchaseDate` and `farewellDate`. Tests exercise it by setting
    /// `purchaseDate`; if `purchaseDate` is nil, `companionshipDays` is nil.
    func makeRecord(
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        recipientDetail: String? = nil,
        emotionValue: Int? = nil,
        farewellLetter: String? = nil,
        photoFilenames: [String] = []
    ) -> FarewellRecord {
        FarewellRecord(
            name: "测试物品",
            category: .builtin(.other),
            method: .donate,
            purchaseDate: purchaseDate,
            recipientDetail: recipientDetail,
            purchasePrice: purchasePrice,
            emotionValue: emotionValue,
            farewellLetter: farewellLetter,
            photoFilenames: photoFilenames
        )
    }

    func testPurchaseDateNilHidden() {
        let r = makeRecord()
        XCTAssertFalse(RemembranceCardModel(record: r).showsPurchaseDate)
    }

    func testPurchaseDatePresentShown() {
        let r = makeRecord(purchaseDate: Date(timeIntervalSince1970: 0))
        XCTAssertTrue(RemembranceCardModel(record: r).showsPurchaseDate)
    }

    func testCompanionshipDaysNilWhenNoPurchaseDate() {
        let r = makeRecord()
        XCTAssertFalse(RemembranceCardModel(record: r).showsCompanionshipDays)
    }

    func testCompanionshipDaysPresentWhenPurchaseDateSet() {
        let r = makeRecord(purchaseDate: Date(timeIntervalSince1970: 0))
        XCTAssertTrue(RemembranceCardModel(record: r).showsCompanionshipDays)
    }

    func testPriceNilHidden() {
        let r = makeRecord()
        XCTAssertFalse(RemembranceCardModel(record: r).showsPrice)
    }

    func testPriceZeroHidden() {
        let r = makeRecord(purchasePrice: 0)
        XCTAssertFalse(RemembranceCardModel(record: r).showsPrice)
    }

    func testPricePositiveShown() {
        let r = makeRecord(purchasePrice: 199)
        XCTAssertTrue(RemembranceCardModel(record: r).showsPrice)
    }

    func testRecipientDetailEmptyHidden() {
        let r = makeRecord(recipientDetail: "")
        XCTAssertFalse(RemembranceCardModel(record: r).showsRecipientDetail)
    }

    func testRecipientDetailPresentShown() {
        let r = makeRecord(recipientDetail: "捐赠给山区")
        XCTAssertTrue(RemembranceCardModel(record: r).showsRecipientDetail)
    }

    func testEmotionNilHidden() {
        let r = makeRecord()
        XCTAssertFalse(RemembranceCardModel(record: r).showsEmotion)
    }

    func testEmotionPresentShown() {
        let r = makeRecord(emotionValue: 2)
        XCTAssertTrue(RemembranceCardModel(record: r).showsEmotion)
    }

    func testLetterEmptyHidden() {
        let r = makeRecord(farewellLetter: "")
        XCTAssertFalse(RemembranceCardModel(record: r).showsLetter)
    }

    func testLetterPresentShown() {
        let r = makeRecord(farewellLetter: "感谢陪伴")
        XCTAssertTrue(RemembranceCardModel(record: r).showsLetter)
    }

    func testPhotoHintNoPhotosHidden() {
        let r = makeRecord(photoFilenames: [])
        XCTAssertFalse(RemembranceCardModel(record: r).showsPhotoHint)
    }

    func testPhotoHintWithPhotosShown() {
        let r = makeRecord(photoFilenames: ["a.jpg"])
        XCTAssertTrue(RemembranceCardModel(record: r).showsPhotoHint)
    }
}
