//
//  VideoContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 05/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct VideoDetailContext: Content, Encodable {
    var video: Video
    var tags: [String]
}


struct VideoContext: Content, Encodable {
    var videos: [Video]
}
