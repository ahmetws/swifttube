import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    router.get { req in
        return try req.view().render("index")
    }
    
    router.get("tag", String.parameter) { req in
        return try req.view().render("tag", ["tag": req.parameters.next(String.self)])
    }
}
