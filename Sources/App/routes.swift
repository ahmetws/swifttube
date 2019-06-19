import Vapor
import MongoKitten
import Paginator

public func routes(_ router: Router) throws {

    let apiClient: APIProtocol = APIClient()
    let searchAPIClient: SearchAPIProtocol = SearchAPIClient()

    router.get { req -> EventLoopFuture<View> in
        let db = try req.getDb()
        return apiClient.getFeaturedVideos(db)
            .and(apiClient.getFeaturedConferences(db))
            .map({ (result) -> HomeContext in
                let context = HomeContext(videos: result.0, conferences: result.1)
                return context
            })
            .flatMap({ context in
                return try req.view().render("index", context)
            })
    }
    
    router.get("speakers") { req -> EventLoopFuture<View> in
        let speakersFuture = apiClient.getSpeakers(try req.getDb())
        
        return speakersFuture.flatMap({ speakers in
            return try req.view().render("speakers", ["speakers": speakers])
        })
    }

    router.get("speakers") { (req: Request) -> EventLoopFuture<Response> in
        let speakersFuture = apiClient.getSpeakers(try req.getDb())
        
        return speakersFuture.flatMap({ (speakers) in
            let paginator: Future<OffsetPaginator<Speaker>> = try speakers.paginate(for: req)
            return paginator.flatMap(to: Response.self) { paginator in
                return try req.view().render(
                    "speakers",
                    SpeakersContext(speakers: paginator.data ?? []),
                    userInfo: try paginator.userInfo()
                    )
                    .encode(for: req)
            }
        })
    }
    
    router.get("videos") { (req: Request) -> EventLoopFuture<Response> in
        return apiClient.getVideos(try req.getDb()).flatMap({ (videos) -> EventLoopFuture<Response> in
            let paginator: Future<OffsetPaginator<Video>> = try videos.paginate(for: req)

            return try paginator.flatMap({ (offset) -> EventLoopFuture<Response> in
                return try! req.view().render("videos", VideoContext.init(videos: offset.data ?? []), userInfo: try offset.userInfo()).encode(for: req)
            })
            .encode(for: req)
        })
    }
    
    router.get("random") { (req: Request) -> EventLoopFuture<View> in
        return apiClient.getRandomVideo(try req.getDb()).flatMap({ video -> EventLoopFuture<View> in

            guard let randomVideo = video else {
                return try req.view().render("404")
            }

            let tags: [String] = randomVideo.tags?.map({ value in
                return String(describing: value.1)
            }) ?? []

            let context = VideoDetailContext(video: randomVideo, twitterText: randomVideo.twitterText, tags: tags)
            return try req.view().render("video", context)
        })
    }
    
    router.get("conferences") { req -> EventLoopFuture<View> in
        let conferences = apiClient.getConferences(try req.getDb())
        return try req.view().render("conferences", ["conferences": conferences])
    }

    router.get("conference", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)

        return apiClient.getConference(try req.getDb(), shortUrl: value).flatMap({ (conference) -> EventLoopFuture<View> in
            let confId = conference!["_id"]!

            return apiClient.getConferenceVideos(try req.getDb(), conferenceId: confId).flatMap({ (videos) -> EventLoopFuture<View> in
                let context = ConferenceContext.init(videos: videos, conference: conference!)
                return try req.view().render("conference", context)
            })
        })
    }
    
    router.get("video", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)

        return apiClient.getVideo(try req.getDb(), shortUrl: value).flatMap({ video -> EventLoopFuture<View> in

            guard let video = video else {
                return try req.view().render("404")
            }

            let tags: [String] = video.tags?.map({ value in
                return String(describing: value.1)
            }) ?? []

            let context = VideoDetailContext(video: video, twitterText: video.twitterText, tags: tags)
            return try req.view().render("video", context)
        })
    }
    
    router.get("speaker", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)

        return apiClient.getSpeaker(try req.getDb(), shortUrl: value).flatMap({ (speaker) -> EventLoopFuture<View> in
            guard let speakerId = speaker?["_id"] else {
                return try req.view().render("index")
            }
            
            guard let speakerVideosFuture = apiClient.getSpeakerVideos(try req.getDb(), speakerId: speakerId) else {
                return try req.view().render("index")
            }
            
            return speakerVideosFuture.flatMap({ (videos) in
                let context = SpeakerContext.init(videos: videos, speaker: speaker!)
                return try req.view().render("speaker", context)
            })
        })
    }
    
    router.get("tag", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)

        return apiClient.getTagVideos(try req.getDb(), tag: value).flatMap({ videos in
            let context = TagContext.init(videos: videos, tag: value)
            return try req.view().render("tag", context)
        })
    }

    // MARK: - Event

    router.get("events") { req -> EventLoopFuture<View> in
        let db = try req.getDb()
        let events = apiClient.getEvents(db)
        return try req.view().render("events", ["events": events])
    }

    router.get("event", String.parameter) { req -> EventLoopFuture<View> in
        let value = try req.parameters.next(String.self)
        let db = try req.getDb()

        return apiClient.getEvent(db, shortUrl: value)
            .flatMap({ (event) -> EventLoopFuture<View> in
                guard let eventId = event?._id else {
                    return try req.view().render("index")
                }

                return apiClient.getEventVideos(db, eventId: eventId).flatMap({ (videos) -> EventLoopFuture<View> in
                    let context = EventContext(videos: videos, event: event!)
                    return try req.view().render("event", context)
                })
            })
    }

    // MARK: - Today's Video

    router.get("today") { (req: Request) -> EventLoopFuture<View> in
        let video = apiClient.getTodaysVideo(try req.getDb())

        return video.flatMap({ maybeVideo -> EventLoopFuture<View> in

            guard let unwrapped = maybeVideo else {
                return try req.view().render("404")
            }

            let tags: [String] = unwrapped.tags?.map({ value in
                return String(describing: value)
            }) ?? []

            let context = VideoDetailContext(video: unwrapped, twitterText: unwrapped.twitterText, tags: tags)
            return try req.view().render("video", context)
        })
    }
    
    // MARK: - RSS

    router.get("rss") { req -> EventLoopFuture<Response> in
        return apiClient.getLatestVideos(try req.getDb(), limit: 20).map({ videos in
            let rssGenerator = RSSFeedGenerator(videoList: videos)
            let xmlFeed = rssGenerator.feedHandler()
            
            var httpRes = HTTPResponse(status: .ok, body: xmlFeed)
            httpRes.headers.replaceOrAdd(name:"Content-Type", value: "application/rss+xml")
            
            return Response(http: httpRes, using: req)
        })
    }
    
    // MARK: - Search
    
    router.get("search", String.parameter) { req -> EventLoopFuture<View> in
        let db = try req.getDb()

        let searchText = try req.parameters.next(String.self)
        searchAPIClient.save(db, searchText: searchText)

        return getSearchContext(db, for: searchText).flatMap({ context in
            return try req.view().render("search", context)
        })
    }

    router.post("search") { req -> EventLoopFuture<View> in
        let db = try req.getDb()

        let searchText: String = try req.content.syncGet(at: "searchText")
        searchAPIClient.save(try req.getDb(), searchText: searchText)

        return getSearchContext(db, for: searchText).flatMap({ context in
            return try req.view().render("search", context)
        })
    }

    func getSearchContext(_ db: MongoKitten.Database, for searchText: String) -> EventLoopFuture<SearchContext> {
        return searchAPIClient.getSearchedSpeakers(db, searchText: searchText)
            .and(searchAPIClient.getSearchedConferences(db, searchText: searchText))
            .and(searchAPIClient.getSearchedVideos(db, searchText: searchText))
            .map ({ (result) -> SearchContext in
                var hasResult = true
                if result.0.0.isEmpty && result.0.1.isEmpty && result.1.isEmpty {
                    hasResult = false
                }

                let context = SearchContext(videos: result.1, conferences: result.0.1, speakers: result.0.0, hasResult: hasResult)
                return context
            })
    }
}

private extension Request {
    func getDb() throws -> MongoKitten.Database {
        return try make(MongoKitten.Database.self)
    }
}
