import Vapor
import MongoKitten
import Paginator

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    let databaseUrl = Environment.get("DB_URL")
    let apiClient: APIProtocol = APIClient(databaseUrl: databaseUrl)
    let searchAPIClient: SearchAPIProtocol = SearchAPIClient(databaseUrl: databaseUrl)

    router.get { req -> EventLoopFuture<View> in
        guard let videos = apiClient.getFeaturedVideos() else {
            return try req.view().render("index")
        }
        
        guard let conferences = apiClient.getFeaturedConferences() else {
            return try req.view().render("index")
        }
        
        let context = HomeContext.init(videos: videos, conferences: conferences)
        return try req.view().render("index", context)
    }
    
    router.get("speakers") { req -> EventLoopFuture<View> in
        guard let speakers = apiClient.getSpeakers() else {
            return try req.view().render("speakers")
        }
        
        return try req.view().render("speakers", ["speakers": speakers])
    }
    
    router.get("speakers") { (req: Request) -> EventLoopFuture<Response> in
        let speakers = apiClient.getSpeakers() ?? []
        
        let paginator: Future<OffsetPaginator<Speaker>> = try speakers.paginate(for: req)
        return paginator.flatMap(to: Response.self) { paginator in
            return try req.view().render(
                "speakers",
                SpeakersContext(speakers: paginator.data ?? []),
                userInfo: try paginator.userInfo()
                )
                .encode(for: req)
        }
    }
    
    router.get("videos") { (req: Request) -> EventLoopFuture<Response> in
        
        let videos = apiClient.getVideos() ?? []
        
        let paginator: Future<OffsetPaginator<Video>> = try videos.paginate(for: req)
        return paginator.flatMap(to: Response.self) { paginator in
            return try req.view().render(
                "videos",
                VideoContext.init(videos: paginator.data ?? []),
                userInfo: try paginator.userInfo()
                )
                .encode(for: req)
        }
    }
    
    router.get("random") { (req: Request) -> EventLoopFuture<View> in
        guard let video = apiClient.getRandomVideo() else {
            return try req.view().render("404")
        }
        
        let tags: [String] = video.tags?.arrayRepresentation.map({ value in
            return String(describing: value)
        }) ?? []
        
        let context = VideoDetailContext(video: video, twitterText: video.twitterText, tags: tags)
        return try req.view().render("video", context)
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
            return try req.view().render("404")
        }
                
        let tags: [String] = video.tags?.arrayRepresentation.map({ value in
            return String(describing: value)
        }) ?? []
        
        let context = VideoDetailContext(video: video, twitterText: video.twitterText, tags: tags)
        return try req.view().render("video", context)
    }
    
    router.get("speaker", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        guard let speaker = apiClient.getSpeaker(shortUrl: value) else {
            return try req.view().render("speaker")
        }
        
        let speakerId = speaker["_id"]!

        guard let videos = apiClient.getSpeakerVideos(speakerId: speakerId) else {
            return try req.view().render("index")
        }
        
        let context = SpeakerContext.init(videos: videos, speaker: speaker)
        return try req.view().render("speaker", context)
    }
    
    router.get("tag", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        
        guard let videos = apiClient.getTagVideos(tag: value) else {
            return try req.view().render("index")
        }
        
        let context = TagContext.init(videos: videos, tag: value)
        return try req.view().render("tag", context)
    }
    
    // MARK: - Search
    
    router.get("search", String.parameter) { req -> EventLoopFuture<View> in
        let searchText = try req.parameters.next(String.self)
        searchAPIClient.save(searchText: searchText)
        
        let context = getSearchContext(for: searchText)
        return try req.view().render("search", context)
    }
    
    router.post("search") { req -> EventLoopFuture<View> in
        let searchText: String = try req.content.syncGet(at: "searchText")
        searchAPIClient.save(searchText: searchText)

        let context = getSearchContext(for: searchText)
        return try req.view().render("search", context)
    }
    
    func getSearchContext(for searchText: String) -> SearchContext {
        let speakers = searchAPIClient.getSearchedSpeakers(searchText: searchText) ?? []
        let conferences = searchAPIClient.getSearchedConferences(searchText: searchText) ?? []
        let videos = searchAPIClient.getSearchedVideos(searchText: searchText) ?? []
        let tags = searchAPIClient.getSearchedTags(searchText: searchText) ?? []
        
        var hasResult = true
        if speakers.isEmpty && conferences.isEmpty && videos.isEmpty && tags.isEmpty  {
            hasResult = false
        }
        
        let context = SearchContext(videos: videos, conferences: conferences, speakers: speakers, tags: tags, hasResult: hasResult)
        return context
    }
}
