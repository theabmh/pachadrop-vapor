import Vapor

func routes(_ app: Application) throws {
    // Health check (unversioned)
    try app.register(collection: HealthController())

    // Root endpoint
    app.get { req async in
        BaseResponseModel<[String: String]>.success(
            ["version": "1.0", "api_base": "/api/v1"],
            message: "E-Commerce API"
        )
    }

    // API v1 controllers
    try app.register(collection: AuthController())
    try app.register(collection: CategoryController())
    try app.register(collection: ProductController())
    try app.register(collection: CartController())
    try app.register(collection: OrderController())
}
