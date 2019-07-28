import MongoKitten
import Vapor

struct EventContext: Content {
    var videos: [Video]
    var event: Event
    var isUpcoming: Bool
    
    init(videos: [Video], event: Event, isUpcoming: Bool) {
        videos.forEach{ $0.setIsUpcoming() }
        self.videos = videos
        self.event = event
        self.isUpcoming = isUpcoming
    }
}
