import Fluent

struct CreateCart: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("carts")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("carts").delete()
    }
}
