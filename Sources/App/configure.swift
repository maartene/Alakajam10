import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    app.lifecycle.use(CreateSimulation())
    
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
    
    // setup Leaf
    app.views.use(.leaf)
    
    // Setup custom tags
    app.leaf.tags[DecimalTag.name] = DecimalTag()
    app.leaf.tags[ZeroDecimalTag.name] = ZeroDecimalTag()
    
    app.middleware.use(app.sessions.middleware)
}
