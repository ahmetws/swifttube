//
//  SearchAPIProtocol.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 06/01/2019.
//

import Foundation
import MongoKitten

protocol SearchAPIProtocol {
    func getSearchedSpeakers(_ db: Database, searchText: String) -> EventLoopFuture<[Document]>
    func getSearchedConferences(_ db: Database, searchText: String) -> EventLoopFuture<[Document]>
    func getSearchedVideos(_ db: Database, searchText: String) -> EventLoopFuture<[Video]>
    func save(_ db: Database, searchText: String)
}
