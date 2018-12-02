//
//  APIProtocol.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 02/12/2018.
//

import Foundation
import MongoKitten

protocol APIProtocol {
    
    func getFeaturedVideos() -> Array<Document>?
    func getVideo(shortUrl: String) -> Document?
}
