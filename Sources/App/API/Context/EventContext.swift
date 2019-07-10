import MongoKitten
import Vapor

struct EventContext: Content {
    var videos: [Video]
    var event: Event
    
    init(videos: [Video], event: Event ) {
        videos.forEach{ $0.setIsUpComing() }
        self.videos = videos
        self.event = event
    }
    
}
