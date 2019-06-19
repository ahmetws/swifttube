import Foundation
import MongoKitten

class APIClient: APIProtocol {
    
    init() {}
    
    private func getAggregatedVideos(_ db: Database) -> AggregateCursor<Document> {
        return db[.videos]
            .aggregate()
            .lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
            .lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
            .lookup(from: "events", localField: "event", foreignField: "_id", as: "eventsArray")
    }
    
    func getVideos(_ db: Database) -> EventLoopFuture<[Video]> {
        let sort: Sort = [
            "videoDate": .descending
        ]
        
        return getAggregatedVideos(db)
            .sort(sort)
            .decode(Video.self)
            .getAllResults()
    }
    
    func getLatestVideos(_ db: Database, limit: Int?) -> EventLoopFuture<[Video]> {
        let sort: Sort = [
            "createdAt": .descending
        ]
        
        let videos = db[.videos]
        
        let cursor: FindCursor
        
        if let limitSize = limit {
            cursor = videos.find().sort(sort).limit(limitSize)
        } else {
            cursor = videos.find().sort(sort)
        }
        
        return cursor
            .decode(Video.self)
            .getAllResults()
    }
    
    func getFeaturedVideos(_ db: Database) -> EventLoopFuture<[Video]> {
        return getAggregatedVideos(db)
            .match("featured" == true)
            .limit(9)
            .decode(Video.self)
            .getAllResults()
    }
    
    func getRandomVideo(_ db: Database) -> EventLoopFuture<Video?> {
        let sampleStage: Document = [
            "$sample": [
                "size": 1
            ]
        ]

        return getAggregatedVideos(db)
            .append(sampleStage)
            .decode(Video.self)
            .getFirstResult()
    }
    
    func getTodaysVideo(_ db: Database) -> EventLoopFuture<Video?> {
        let nowDate = Date()
        let query: Query = [
            "currentDate": [
                "$gte": nowDate.startOfDay,
                "$lt": nowDate.endOfDay
            ]
        ]
        
        let videos = db[.todaysVideo]

        return videos.aggregate()
            .match(query)
            .getFirstResult()
            .map(to: String.self, { (document) -> String in
                guard let document = document,
                    let videoId = document["videoId"] as? String else {
                        // Video id not found
                        throw NSError(domain: "", code: 111, userInfo: nil)
                }
                return videoId
            })
            .flatMap({ (videoId) -> EventLoopFuture<Video?> in
                return self.getVideo(db, videoId: videoId)
            })
    }
    
    func getVideo(_ db: Database, shortUrl: String) -> EventLoopFuture<Video?> {
        return getAggregatedVideos(db)
            .match("shortUrl" == shortUrl)
            .decode(Video.self)
            .getFirstResult()
    }

    func getVideo(_ db: Database, videoId: String?) -> EventLoopFuture<Video?> {
        return getAggregatedVideos(db)
            .match("_id" == videoId)
            .decode(Video.self)
            .getFirstResult()
    }

    //MARK: - Speakers
    
    func getSpeakers(_ db: Database) -> EventLoopFuture<[Speaker]> {
        let sort: Sort = [
            "fullname": .ascending
        ]
        
        return db[.users].find().sort(sort).decode(Speaker.self).getAllResults()
    }
    
    func getSpeaker(_ db: Database, shortUrl: String) -> EventLoopFuture<Document?> {
        return db[.users].findOne("shortname" == shortUrl)
    }
    
    func getSpeakerVideos(_ db: Database, speakerId: Primitive) -> EventLoopFuture<[Video]>? {
        guard let str = speakerId as? String else {
            return nil
        }
        
        let query: Query = [
            "users": [
                "$elemMatch": [
                    "$eq": str
                ]
            ]
        ]
        
        return getAggregatedVideos(db)
            .match(query)
            .decode(Video.self)
            .getAllResults()
    }
    
    func getConferences(_ db: Database) -> EventLoopFuture<[Document]> {
        return db[.conferences].find().getAllResults()
    }
    
    func getFeaturedConferences(_ db: Database) -> EventLoopFuture<[Document]> {
        return db[.conferences].find("featured" == true).limit(6).getAllResults()
    }
    
    func getConference(_ db: Database, shortUrl: String) -> EventLoopFuture<Document?> {
        return db[.conferences].findOne("shortname" == shortUrl)
    }
    
    func getConferenceVideos(_ db: Database, conferenceId: Primitive) -> EventLoopFuture<[Video]> {
        return getAggregatedVideos(db)
            .match("conferences" == conferenceId)
            .sort(["videoDate": .descending])
            .decode(Video.self)
            .getAllResults()
    }

    // MARK: - Event

    func getEvents(_ db: Database) -> EventLoopFuture<[Event]> {
        return db[.events]
            .find()
            .decode(Event.self)
            .getAllResults()
    }

    func getEvent(_ db: Database, shortUrl: String) -> EventLoopFuture<Event?> {
        return db[.events]
            .findOne("shortname" == shortUrl)
            .map({ (document) in
                if let document = document {
                    return try BSONDecoder().decode(Event.self, from: document)
                } else {
                    return nil
                }
            })
    }

    func getEventVideos(_ db: Database, eventId: Primitive) -> EventLoopFuture<[Video]>	 {
        return getAggregatedVideos(db)
            .match("event" == eventId)
            .sort(["videoDate": .descending])
            .decode(Video.self)
            .getAllResults()
    }
    
    func getTagVideos(_ db: Database, tag: String) -> EventLoopFuture<[Video]> {
        let query: Query = [
            "tags": [
                "$elemMatch": [
                    "$eq": tag
                ]
            ]
        ]
        
        return getAggregatedVideos(db)
            .match(query)
            .decode(Video.self)
            .getAllResults()
    }
}

// Extension

private extension String {
    static let videos = "videos"
    static let todaysVideo = "todaysVideo"
    static let users = "users"
    static let conferences = "conferences"
    static let events = "events"
}
