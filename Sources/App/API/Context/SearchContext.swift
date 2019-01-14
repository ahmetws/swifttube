//
//  SearchContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 06/01/2019.
//

import Foundation
import MongoKitten
import Vapor

struct SearchContext: Content {
    var videos: [Video]
    var conferences: [Document]
    var speakers: [Document]
    var tags: [Document]
    var hasResult: Bool
}
