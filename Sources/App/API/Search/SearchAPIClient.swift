import Foundation
import MongoKitten

class SearchAPIClient: SearchAPIProtocol {
    
    private func getAggregatedVideos(_ db: Database, searchText: String) -> AggregateCursor<Document> {
        let query: Query = [
            "$text": ["$search": searchText ]
        ]

        return db["videos"]
            .aggregate()
            .match(query)
            .lookup(from: "conferences", localField: "conferences", foreignField: "_id", as: "conferencesArray")
            .lookup(from: "users", localField: "users", foreignField: "_id", as: "speakersArray")
            .lookup(from: "events", localField: "event", foreignField: "_id", as: "eventsArray")
    }
    
    init() {}
    
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
        return getAggregatedVideos(db, searchText: searchText)
            .sort(["videoDate": .descending])
            .decode(Video.self)
            .getAllResults()
    }
    
    func save(_ db: Database, searchText: String) {
        _ = db["searchText"].insert(["searchText": searchText, "createdAt": Date()])
    }
}

