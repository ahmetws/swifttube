import Foundation
import MongoKitten
import Vapor

struct SearchContext: Content {
    var videos: [Video]
    var conferences: [Document]
    var speakers: [Document]
    var hasResult: Bool
}
