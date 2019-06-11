import Leaf
import Vapor
import Paginator

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first

    try services.register(LeafProvider())

    services.register(OffsetPaginatorConfig(
        perPage: 18,
        defaultPage: 1
    ))
    
    services.register { _ -> LeafTagConfig in
        var tags = LeafTagConfig.default()
        tags.use([
            "offsetPaginator": OffsetPaginatorTag(templatePath: "Paginator/offsetpaginator")
            ])
        return tags
    }
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
