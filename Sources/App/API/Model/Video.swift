import Foundation
import MongoKitten
import Vapor

final class Video: Content, Codable {
    var image: String?
    var title: String?
    var shortUrl: String?
    var url: String?
    var tags: Document?
    var conferencesArray: [Document]?
    var speakersArray: [Document]?
    var eventsArray: [Document]?
    var external: Bool?
    var createdAt: Date?
    var videoDate: Date?

    lazy var twitterText: String = {
        var text = "I just watched this great video \(title ?? "") by"
        
        if let speakers = speakersArray {
            for (index, speaker) in speakers.enumerated() {
                if index != 0 {
                    text.append(" and")
                }
                
                if let twitter = speaker["twitter"] as? String {
                    text.append(" @\(twitter)")
                } else if let fullname = speaker["fullname"] as? String {
                    text.append(" \(fullname)")
                }
            }
        }
        
        if let conf = conferencesArray?.first {
            if let twitter = conf["twitter"] as? String {
                text.append(" at @\(twitter)")
            } else if let fullname = conf["fullname"] as? String {
                text.append(" at \(fullname)")
            }
        }
        
        text.append(" via @swifttubeco")
        
        return text
    }()
    
    init() { }
    
}
