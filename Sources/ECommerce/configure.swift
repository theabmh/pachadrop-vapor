import Vapor
import Fluent
import FluentPostgresDriver
import JWT

public func configure(_ app: Application) async throws {
    // Configure JWT
    let jwtSecret = Environment.get("JWT_SECRET") ?? "your-secret-key-change-me"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // Configure PostgreSQL database
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

    // Register migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateCart())
    app.migrations.add(CreateCartItem())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateOrderItem())
    app.migrations.add(SeedDatabase())

    // Auto migrate on startup
    try await app.autoMigrate()

    // Register routes
    try routes(app)
}
