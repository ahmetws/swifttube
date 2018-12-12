//
//  ConferenceContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 03/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct ConferenceContext: Content {
    var videos: [Video]
    var conference: Document
}
