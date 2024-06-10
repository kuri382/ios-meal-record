import Foundation

struct Facility: Identifiable, Hashable {
    var id: String
    var facilityName: String
    var submittedAt: Double // TimestampからDoubleに変更

    // Hashableプロトコルに準拠するための実装
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Facility, rhs: Facility) -> Bool {
        return lhs.id == rhs.id
    }
}

struct User: Identifiable, Decodable {
    var id: String
    var userName: String
    var userNumber: String
    var submittedAt: Double
    var facilityId: String
}

struct ImageData: Identifiable {
    var id: String
    var imageUrl: String
    var submittedAt: Double // TimestampからDoubleに変更
    var meals: [Meal]?
}
