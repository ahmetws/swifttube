import Foundation
import MongoKitten

final class Event: Codable {
    var _id: String?
    var fullname: String?
    var shortname: String?
    var website: String?
    var conferencesArray: [Document]?

    init() { }
}
