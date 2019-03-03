//
//  APIProtocol.swift
//  App
//
//  Created by Ahmet Yalcinkaya on 02/12/2018.
//

import Foundation
import MongoKitten

protocol APIProtocol {
    
    func getVideos() -> Array<Video>?
    func getFeaturedVideos() -> Array<Video>?
    func getRandomVideo() -> Video?
    func getVideo(shortUrl: String) -> Video?
    
    func getSpeakers() -> Array<Speaker>?
    func getSpeaker(shortUrl: String) -> Document?
    func getSpeakerVideos(speakerId: Primitive) -> Array<Video>?

    func getConferences() -> Array<Document>?
    func getFeaturedConferences() -> Array<Document>?
    func getConference(shortUrl: String) -> Document?
    func getConferenceVideos(conferenceId: Primitive) -> Array<Video>?

    func getTagVideos(tag: String) -> Array<Video>?
}
