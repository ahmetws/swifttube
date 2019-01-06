//
//  SearchAPIProtocol.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 06/01/2019.
//

import Foundation
import MongoKitten

protocol SearchAPIProtocol {
    func getSearchedConferences(searchText: String) -> Array<Document>?
    func getSearchedVideos(searchText: String) -> Array<Video>?
    func getSearchedTags(searchText: String) -> Array<Document>?
}
