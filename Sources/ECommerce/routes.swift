import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        ["message": "E-Commerce API v1.0"]
    }

    // Register all controllers
    try app.register(collection: AuthController())
    try app.register(collection: CategoryController())
    try app.register(collection: ProductController())
    try app.register(collection: CartController())
    try app.register(collection: OrderController())
}
