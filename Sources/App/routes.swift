import Vapor
import MongoKitten

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    let databaseUrl = Environment.get("DB_URL")
    let apiClient: APIProtocol = APIClient(databaseUrl: databaseUrl)
    
    router.get { req -> EventLoopFuture<View> in
        guard let videos = apiClient.getFeaturedVideos() else {
            return try req.view().render("index")
        }
        
        return try req.view().render("index", ["videos": videos])
    }
    
    router.get("speakers") { req -> EventLoopFuture<View> in
        guard let speakers = apiClient.getSpeakers() else {
            return try req.view().render("speakers")
        }
        
        return try req.view().render("speakers", ["speakers": speakers])
    }
    
    router.get("videos") { req -> EventLoopFuture<View> in
        guard let videos = apiClient.getVideos() else {
            return try req.view().render("index")
        }
        
        return try req.view().render("videos", ["videos": videos])
    }
    
    router.get("conferences") { req -> EventLoopFuture<View> in
        guard let conferences = apiClient.getConferences() else {
            return try req.view().render("index")
        }
        
        return try req.view().render("conferences", ["conferences": conferences])
    }
    
    router.get("conference", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        guard let conference = apiClient.getConference(shortUrl: value) else {
            return try req.view().render("index")
        }
        
        let confId = conference["_id"]!
        
        guard let videos = apiClient.getConferenceVideos(conferenceId: confId) else {
            return try req.view().render("index")
        }
        
        let context = ConferenceContext.init(videos: videos, conference: conference)
        return try req.view().render("conference", context)
    }
    
    router.get("video", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        guard let video = apiClient.getVideo(shortUrl: value) else {
            return try req.view().render("index")
        }
        
        return try req.view().render("video", ["video": video])
    }
    
    router.get("speaker", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        guard let speaker = apiClient.getSpeaker(shortUrl: value) else {
            return try req.view().render("speaker")
        }
        
        return try req.view().render("speaker", ["speaker": speaker])
    }
    
    router.get("tag", String.parameter) { req in
        return try req.view().render("tag", ["tag": req.parameters.next(String.self)])
    }
}
