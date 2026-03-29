import Vapor
import Fluent
import FluentPostgresDriver
import JWT

public func configure(_ app: Application) async throws {
    // Load .env file for local development
    await DotEnvFile.load(path: ".env", fileio: app.fileio)

    // Remove default error middleware and use our custom one
    app.middleware = .init()
    app.middleware.use(AppErrorMiddleware())
    app.middleware.use(RequestLoggingMiddleware())

    // Configure CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .PATCH, .OPTIONS],
        allowedHeaders: [
            .accept, .authorization, .contentType, .origin,
            .xRequestedWith, .init("X-Request-ID")
        ],
        allowCredentials: true
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

    // Configure JWT — fail if no secret in production
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        if app.environment == .production {
            fatalError("JWT_SECRET environment variable is required in production")
        }
        app.logger.warning("JWT_SECRET not set — using default development key")
        app.jwt.signers.use(.hs256(key: "dev-secret-change-me-in-production"))
        configureGoogleOAuth(app)
        configureDatabase(app)
        try await registerMigrations(app)
        try routes(app)
        return
    }
    app.jwt.signers.use(.hs256(key: jwtSecret))
    configureGoogleOAuth(app)

    // Configure PostgreSQL database
    configureDatabase(app)

    // Register migrations
    try await registerMigrations(app)

    // Register routes
    try routes(app)
}

private func configureDatabase(_ app: Application) {
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Int(Environment.get("DATABASE_PORT") ?? "5432") ?? 5432
    let username = Environment.get("DATABASE_USERNAME") ?? "postgres"
    let password = Environment.get("DATABASE_PASSWORD") ?? "postgres"
    let dbName = Environment.get("DATABASE_NAME") ?? "ecommerce"

    app.databases.use(
        .postgres(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: dbName
        ),
        as: .psql
    )
}

private func configureGoogleOAuth(_ app: Application) {
    guard let clientId = Environment.get("GOOGLE_CLIENT_ID") else {
        if app.environment == .production {
            fatalError("GOOGLE_CLIENT_ID environment variable is required in production")
        }
        app.logger.warning("GOOGLE_CLIENT_ID not set — Google OAuth audience check will be skipped in development")
        return
    }
    app.jwt.google.applicationIdentifier = clientId
}

private func registerMigrations(_ app: Application) async throws {
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateCart())
    app.migrations.add(CreateCartItem())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateOrderItem())
    app.migrations.add(SeedDatabase())
    app.migrations.add(AddIndexes())
    app.migrations.add(AddGoogleAuthToUser())

    try await app.autoMigrate()
}
