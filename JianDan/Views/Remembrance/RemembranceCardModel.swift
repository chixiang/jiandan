import Foundation

/// Pure presentation logic for the Remembrance card.
///
/// Encapsulates the "show vs. hide" decisions from the redesign spec (§4.2),
/// keeping them out of the View body so they can be unit-tested without
/// SwiftUI.
struct RemembranceCardModel {
    let record: FarewellRecord

    var showsPurchaseDate: Bool { record.purchaseDate != nil }
    var showsCompanionshipDays: Bool { record.companionshipDays != nil }
    var showsPrice: Bool { (record.purchasePrice ?? 0) > 0 }
    var showsRecipientDetail: Bool {
        guard let d = record.recipientDetail else { return false }
        return !d.isEmpty
    }
    var showsEmotion: Bool { record.emotionValue != nil }
    var showsLetter: Bool {
        guard let l = record.farewellLetter else { return false }
        return !l.isEmpty
    }
    var showsPhotoHint: Bool { !record.photoFilenames.isEmpty }
}
