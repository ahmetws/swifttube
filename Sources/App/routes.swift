import Vapor

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
    
    router.get("video", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        guard let video = apiClient.getVideo(shortUrl: value) else {
            // TODO: Article not found
            return try req.view().render("index")
        }
        
        // TODO: Present article
        return try req.view().render("video", ["video": video])
    }
    
    router.get("tag", String.parameter) { req in
        return try req.view().render("tag", ["tag": req.parameters.next(String.self)])
    }
}
