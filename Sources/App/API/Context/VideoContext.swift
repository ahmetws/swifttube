//
//  VideoContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 05/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct VideoContext: Content, Encodable {
    var videos: [Video]
}
