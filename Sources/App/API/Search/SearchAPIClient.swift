//
//  SearchAPIClient.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 06/01/2019.
//

import Foundation
import MongoKitten

class SearchAPIClient: SearchAPIProtocol {
    
    let database: Database?
    
    init(databaseUrl: String?) {
        if let url = databaseUrl {
            database = try? Database(url)
        } else {
            database = nil
            assert(false, "URL can not be nil")
        }
    }
    
    func getSearchedSpeakers(searchText: String) -> Array<Document>? {
        guard let database = database else { return nil }
        
        let query: Query = Query.textSearch(forString: searchText)
        
        let speakers = try? Array(database["users"].find(query))
        return speakers
    }
    
    func getSearchedConferences(searchText: String) -> Array<Document>? {
        guard let database = database else { return nil }
        
        let query: Query = Query.textSearch(forString: searchText)
        
        let conferences = try? Array(database["conferences"].find(query))

        return conferences
    }
    
    func getSearchedVideos(searchText: String) -> Array<Video>? {
        guard let database = database else { return nil }
        
        let query: Query = Query.textSearch(forString: searchText)
        let matchQuery = AggregationPipeline.Stage.match(query)
        let sort = AggregationPipeline.Stage.sort(["videoDate": .descending])

        var stages = Video.lookupList()
        stages.insert(matchQuery, at: 0)
        stages.append(sort)

        let pipe = AggregationPipeline(arrayLiteral: stages)

        let videos = try? Array(database["videos"].aggregate(pipe).makeIterator()).map({ document in
            return try BSONDecoder().decode(Video.self, from: document)
        })
        
        return videos
    }
    
    func getSearchedTags(searchText: String) -> Array<Document>? {
        return []
    }
    
    func save(searchText: String) {
        guard let database = database else { return }
        _ = try? database["searchText"].insert(["searchText": searchText, "createdAt": Date()])
    }
}

