//
//  SpeakerContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 03/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct SpeakersContext: Content {
    var speakers: [Speaker]
}

struct SpeakerContext: Content {
    var videos: [Video]
    var speaker: Document
    
    init(videos: [Video], speaker: Document) {
        videos.forEach{ $0.setIsUpcoming() }
        self.videos = videos
        self.speaker = speaker
    }
}
