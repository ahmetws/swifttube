//
//  TagContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 03/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct TagContext: Content {
    var videos: [Video]
    var tag: String
}
