//
//  SearchAPIClient.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 06/01/2019.
//

import Foundation
import MongoKitten

class SearchAPIClient: SearchAPIProtocol {
    
    private func getAggregatedVideos(_ db: Database) -> AggregateCursor<Document> {
        return db["videos"]
            .aggregate()
            .lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
            .lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
            .lookup(from: "events", localField: "event", foreignField: "_id", as: "eventsArray")
    }
    
    init() {}
    
//    let database: Database?
//
//    init(databaseUrl: String?) {
//        if let url = databaseUrl {
//            database = try? Database.synchronousConnect(url)
//        } else {
//            database = nil
//            assert(false, "URL can not be nil")
//        }
//    }
    
    func getSearchedSpeakers(_ db: Database, searchText: String) -> EventLoopFuture<[Document]> {
        let query: Query = [
            "$text": ["$search": searchText ]
        ]
        
        return db["users"]
            .find(query)
            .getAllResults()
    }
    
    func getSearchedConferences(_ db: Database, searchText: String) -> EventLoopFuture<[Document]> {
        let query: Query = [
            "$text": ["$search": searchText ]
        ]
        
        return db["conferences"]
            .find(query)
            .getAllResults()
    }
    
    func getSearchedVideos(_ db: Database, searchText: String) -> EventLoopFuture<[Video]> {
        let query: Query = [
            "$text": ["$search": searchText ]
        ]
        
        return getAggregatedVideos(db)
            .match(query)
            .sort(["videoDate": .descending])
            .decode(Video.self)
            .getAllResults()
    }
    
//    func getSearchedTags(searchText: String) -> EventLoopFuture<[Document]> {
//        return []
//    }
    
    func save(_ db: Database, searchText: String) {
        _ = db["searchText"].insert(["searchText": searchText, "createdAt": Date()])
    }
}

