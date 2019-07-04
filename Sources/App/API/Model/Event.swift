import Foundation
import MongoKitten

final class Event: Codable {
    var _id: String?
    var fullname: String?
    var shortname: String?
    var website: String?
    var conferencesArray: [Document]?
    var startDate: Date?
    var isUpcoming: Bool {
        guard let date = startDate else { return false }
        return date.isFuture(from: Date())
    }

    init() { }
}
