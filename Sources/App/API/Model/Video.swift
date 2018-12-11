//
//  Video.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 11/12/2018.
//

import Foundation
import MongoKitten

final class Video: Codable {
    var image: String?
    var title: String?
    var shortUrl: String?
    var conferencesArray: [Document]?
    var speakersArray: [Document]?

    init() { }

    
}
