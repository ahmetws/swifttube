//
//  APIClient.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 02/12/2018.
//

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
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")

        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])
        let pipe = AggregationPipeline(arrayLiteral: lookupConferences, lookupSpeakers, sort)
        
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return videos
    }
    
    func getFeaturedVideos() -> Array<Video>? {
        guard let database = database else { return nil }
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        let matchFeatured = AggregationPipeline.Stage.match("featured" == true)
        let sampleStage = AggregationPipeline.Stage.sample(sizeOf: 8)
        
        let pipe = AggregationPipeline(arrayLiteral: matchFeatured, lookupConferences, lookupSpeakers, sampleStage)
        
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
    
    func getRandomVideo() -> Video? {
        guard let database = database else { return nil }
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        let sampleStage = AggregationPipeline.Stage.sample(sizeOf: 1)
        
        let pipe = AggregationPipeline(arrayLiteral: sampleStage, lookupConferences, lookupSpeakers)

        let randomVideo = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return randomVideo?.first
    }
    
    func getVideo(shortUrl: String) -> Video? {
        guard let database = database else { return nil }

        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        let matchStage = AggregationPipeline.Stage.match("shortUrl" == shortUrl)
        
        let pipe = AggregationPipeline(arrayLiteral: matchStage, lookupConferences, lookupSpeakers)
        
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
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        
        let query: Query = [
            "users": [
                "$elemMatch": [
                    "$eq": speakerId
                ]
            ]
        ]
        let matchQuery = AggregationPipeline.Stage.match(query)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])

        let pipe = AggregationPipeline(arrayLiteral: matchQuery, lookupConferences, lookupSpeakers, sort)
        
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
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        let matchQuery = AggregationPipeline.Stage.match("conferences" == conferenceId)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])

        let pipe = AggregationPipeline(arrayLiteral: matchQuery, lookupConferences, lookupSpeakers, sort)
        
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
    
    func getTagVideos(tag: String) -> Array<Video>? {
        guard let database = database else { return nil }
        
        let lookupConferences = AggregationPipeline.Stage.lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
        let lookupSpeakers = AggregationPipeline.Stage.lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
        
        let query: Query = [
            "tags": [
                "$elemMatch": [
                    "$eq": tag
                ]
            ]
        ]
        let matchQuery = AggregationPipeline.Stage.match(query)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])

        let pipe = AggregationPipeline(arrayLiteral: matchQuery, lookupConferences, lookupSpeakers, sort)
        
        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        return videos
    }
}
