//
//  HomeContext.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 04/12/2018.
//

import Foundation
import MongoKitten
import Vapor

struct HomeContext: Content {
    var videos: [Video]
    var conferences: [Document]
    var events: [Event]
}
