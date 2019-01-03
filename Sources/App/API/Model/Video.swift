//
//  Video.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 11/12/2018.
//

import Foundation
import MongoKitten
import Vapor

final class Video: Content, Codable {
    var image: String?
    var title: String?
    var shortUrl: String?
    var url: String?
    var conferencesArray: [Document]?
    var speakersArray: [Document]?

    init() { }

    
}
