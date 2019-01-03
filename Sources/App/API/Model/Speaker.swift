//
//  Speaker.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 03/01/2019.
//

import Foundation
import MongoKitten

final class Speaker: Codable {
    var image: String?
    var fullname: String?
    var shortname: String?
    var twitter: String?
    
    init() { }
}
