import Vapor
import Foundation

// Taken by SteamPress
// https://github.com/brokenhandsio/SteamPress/blob/master/Sources/SteamPress/Feed%20Generators/RSSFeedGenerator.swift
struct RSSFeedGenerator {
    
    // MARK: - Properties
    
    let rfc822DateFormatter: DateFormatter
    let xmlEnd = "</channel>\n\n</rss>"
    let videoList: [Video]
    
    // MARK: - Initialiser
    
    init(videoList: [Video]) {
        self.videoList = videoList
        
        rfc822DateFormatter = DateFormatter()
        rfc822DateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        rfc822DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc822DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    
    // MARK: - Route Handler
    
    func feedHandler() -> String {
        
        var xmlFeed = getXMLStart()
        
        if !videoList.isEmpty {
            let videoDate = videoList[0].createdAt ?? Date()
            xmlFeed += "<pubDate>\(rfc822DateFormatter.string(from: videoDate))</pubDate>\n"
        }
        
        for video in videoList {
            xmlFeed += video.getVideoRSSFeed(dateFormatter: rfc822DateFormatter)
        }
        
        xmlFeed += xmlEnd
        return xmlFeed
    }
    
    // MARK: - Private functions
    
    private func getXMLStart() -> String {
        var start = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<rss version=\"2.0\">\n\n<channel>\n<title>\(AppConstants.title)</title>\n<link>\(AppConstants.link)</link>\n<description>\(AppConstants.description)</description>\n<generator>Swifttube</generator>\n<ttl>60</ttl>\n"
        
        start += "<copyright>\(AppConstants.copyright)</copyright>\n"
        start += "<image>\n<url>\(AppConstants.imageURL)</url>\n<title>\(AppConstants.title)</title>\n<link>\(AppConstants.link)</link>\n</image>\n"
        
        return start
    }
}

extension Video {
    func getVideoRSSFeed(dateFormatter: DateFormatter) -> String {
        
        var videoEntry = "<item>\n<title>\n\(title ?? "")\n</title>\n"

        videoEntry += "<description>\n\(videoDescription())\n</description>\n"

        if let shortUrl = shortUrl {
            let link = AppConstants.rootPath + AppConstants.videoPath + "/\(shortUrl)/"
            videoEntry += "<link>\n\(link)\n</link>\n"
            videoEntry += "<guid>\n\(link)\n</guid>\n"
        }
        
        if let conf = conferencesArray?.first {
            if let fullname = conf["fullname"] as? String {
                videoEntry += "<category>\(fullname)</category>\n"
            }
        }

        if let tags = tags {
            for tag in tags {
                videoEntry += "<category>\(tag.0)</category>\n"
            }
        }

        if let createdAt = createdAt {
            videoEntry += "<pubDate>\(dateFormatter.string(from: createdAt))</pubDate>\n"
        }

        videoEntry += "</item>\n"
        return videoEntry
    }
    
    private func videoDescription() -> String {
        var text = "\(title ?? "") by"
        
        if let speakers = speakersArray {
            for (index, speaker) in speakers.enumerated() {
                if index != 0 {
                    text.append(" and")
                }
                
                if let fullname = speaker["fullname"] as? String {
                    text.append(" \(fullname)")
                }
            }
        }
        
        if let conf = conferencesArray?.first {
            if let fullname = conf["fullname"] as? String {
                text.append(" at \(fullname)")
            }
        }
        return text
    }
}
