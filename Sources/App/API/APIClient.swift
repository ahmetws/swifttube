import Foundation
import MongoKitten

class APIClient: APIProtocol {
    
    let database: Database?
    
    init(databaseUrl: String?) {
        if let url = databaseUrl {
            database = try? Database(url)
        } else {
            database = nil
            assert(false, "URL can not be nil")
        }
    }
    
    func getVideos() -> Array<Video>? {
        guard let database = database else { return nil }

        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        var stages = Video.lookupList()
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return videos
    }
    
    func getLatestVideos(limit: Int?) -> Array<Video>? {
        guard let database = database else { return nil }

        let sort = AggregationPipeline.Stage.sort(["createdAt": .descending])
        var stages = Video.lookupList()
        stages.append(sort)

        if let limitSize = limit {
            let limitStage = AggregationPipeline.Stage.limit(limitSize)
            stages.append(limitStage)
        }

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return videos
    }
    
    func getFeaturedVideos() -> Array<Video>? {
        guard let database = database else { return nil }

        let matchQuery = AggregationPipeline.Stage.match("featured" == true)
        let sampleStage = AggregationPipeline.Stage.sample(sizeOf: 8)
        var stages = Video.lookupList()
        stages.append(matchQuery)
        stages.append(sampleStage)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
    
    func getRandomVideo() -> Video? {
        guard let database = database else { return nil }

        let sampleStage = AggregationPipeline.Stage.sample(sizeOf: 1)
        var stages = Video.lookupList()
        stages.append(sampleStage)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let randomVideo = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return randomVideo?.first
    }
    
    func getTodaysVideo() -> Video? {
        guard let database = database else { return nil }

        let nowDate = Date()
        let query: Query = [
            "currentDate": [
                "$gte": nowDate.startOfDay,
                "$lt": nowDate.endOfDay
            ]
        ]
        let matchQuery = AggregationPipeline.Stage.match(query)
        let limitStage = AggregationPipeline.Stage.limit(1)
        let pipe = AggregationPipeline(arrayLiteral: matchQuery, limitStage)

        guard let todaysVideo = try? Array(database["todaysVideo"].aggregate(pipe).makeIterator()),
            let video = todaysVideo.first else {
            return nil
        }

        guard let videoId = video.dictionaryRepresentation["videoId"] as? String else {
            return nil
        }

        return getVideo(videoId: videoId)
    }
    
    func getVideo(shortUrl: String) -> Video? {
        guard let database = database else { return nil }

        let matchQuery = AggregationPipeline.Stage.match("shortUrl" == shortUrl)
        var stages = Video.lookupList()
        stages.append(matchQuery)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })

        return videos?.first
    }

    func getVideo(videoId: String) -> Video? {
        guard let database = database else { return nil }

        let matchQuery = AggregationPipeline.Stage.match("_id" == videoId)
        var stages = Video.lookupList()
        stages.append(matchQuery)

        let pipe = AggregationPipeline(arrayLiteral: stages)

        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })

        return videos?.first
    }

    //MARK: - Speakers
    
    func getSpeakers() -> Array<Speaker>? {
        guard let database = database else { return nil }
        
        let sort: Sort = [
            "fullname": .ascending
        ]
        
        let speakers = try? Array(database["users"].find([:], sortedBy: sort)).map({ document in
            return try BSONDecoder().decode(Speaker.self, from: document)
        })
        
        return speakers
    }
    
    func getSpeaker(shortUrl: String) -> Document? {
        guard let database = database else { return nil }
        
        guard let speaker = try? database["users"].findOne("shortname" == shortUrl) else {
            return nil
        }
        return speaker
    }
    
    func getSpeakerVideos(speakerId: Primitive) -> Array<Video>? {
        guard let database = database else { return nil }

        let query: Query = [
            "users": [
                "$elemMatch": [
                    "$eq": speakerId
                ]
            ]
        ]
        let matchQuery = AggregationPipeline.Stage.match(query)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        var stages = Video.lookupList()
        stages.append(matchQuery)
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
    
    func getConferences() -> Array<Document>? {
        guard let database = database else { return nil }
        
        guard let conferences = try? Array(database["conferences"].find()) else {
            return nil
        }
        return conferences
    }
    
    func getFeaturedConferences() -> Array<Document>? {
        guard let database = database else { return nil }
        
        let query: Query = [
            "featured": true,
        ]

        let matchQuery = AggregationPipeline.Stage.match(query)
        let sampleStage = AggregationPipeline.Stage.sample(sizeOf: 6)
        let pipe = AggregationPipeline(arrayLiteral: matchQuery, sampleStage)

        guard let conferences = try? Array(database["conferences"].aggregate(pipe).makeIterator()) else {
            return nil
        }
        return conferences
    }
    
    func getConference(shortUrl: String) -> Document? {
        guard let database = database else { return nil }
        
        guard let conference = try? database["conferences"].findOne("shortname" == shortUrl) else {
            return nil
        }
        return conference
    }
    
    func getConferenceVideos(conferenceId: Primitive) -> Array<Video>? {
        guard let database = database else { return nil }

        let matchQuery = AggregationPipeline.Stage.match("conferences" == conferenceId)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        var stages = Video.lookupList()
        stages.append(matchQuery)
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }

    // MARK: - Event

    func getEvents() -> Array<Event>? {
        guard let database = database else { return nil }

        let events = try? Array(database["events"].find()).map({ document in
            return try BSONDecoder().decode(Event.self, from: document)
        })
        return events
    }

    func getEvent(shortUrl: String) -> Event? {
        guard let database = database else { return nil }

        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conference", foreignField: "_id", as: "conferencesArray")
        let matchQuery = AggregationPipeline.Stage.match("shortname" == shortUrl)

        let pipe = AggregationPipeline(arrayLiteral: lookupConferences, matchQuery)

        let events = try? Array(database["events"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Event.self, from: document)
        })

        return events?.first
    }

    func getEventVideos(eventId: Primitive) -> Array<Video>? {
        guard let database = database else { return nil }

        let matchQuery = AggregationPipeline.Stage.match("event" == eventId)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        var stages = Video.lookupList()
        stages.append(matchQuery)
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
    
    func getTagVideos(tag: String) -> Array<Video>? {
        guard let database = database else { return nil }
        
        let query: Query = [
            "tags": [
                "$elemMatch": [
                    "$eq": tag
                ]
            ]
        ]
        let matchQuery = AggregationPipeline.Stage.match(query)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        var stages = Video.lookupList()
        stages.append(matchQuery)
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
}

// Extension

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
