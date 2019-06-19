import Foundation
import MongoKitten

protocol APIProtocol {
    
    func getVideos(_ db: Database) -> EventLoopFuture<[Video]>
    func getLatestVideos(_ db: Database, limit: Int?) -> EventLoopFuture<[Video]>
    func getFeaturedVideos(_ db: Database) -> EventLoopFuture<[Video]>
    func getRandomVideo(_ db: Database) -> EventLoopFuture<Video?>
    func getTodaysVideo(_ db: Database) -> EventLoopFuture<Video?>
    func getVideo(_ db: Database, shortUrl: String) -> EventLoopFuture<Video?>
    
    func getSpeakers(_ db: Database) -> EventLoopFuture<[Speaker]>
    func getSpeaker(_ db: Database, shortUrl: String) -> EventLoopFuture<Document?>
    func getSpeakerVideos(_ db: Database, speakerId: Primitive) -> EventLoopFuture<[Video]>?

    func getConferences(_ db: Database) -> EventLoopFuture<[Document]>
    func getFeaturedConferences(_ db: Database) -> EventLoopFuture<[Document]>
    func getConference(_ db: Database, shortUrl: String) -> EventLoopFuture<Document?>
    func getConferenceVideos(_ db: Database, conferenceId: Primitive) -> EventLoopFuture<[Video]>

    func getEvents(_ db: Database) -> EventLoopFuture<[Event]>
    func getEvent(_ db: Database, shortUrl: String) -> EventLoopFuture<Event?>
    func getEventVideos(_ db: Database, eventId: Primitive) -> EventLoopFuture<[Video]>

    func getTagVideos(_ db: Database, tag: String) -> EventLoopFuture<[Video]>
}
