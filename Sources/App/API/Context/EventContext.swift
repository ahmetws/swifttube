import MongoKitten
import Vapor

struct EventContext: Content {
    var videos: [Video]
    var event: Event
}
