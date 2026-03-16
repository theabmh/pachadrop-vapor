import Fluent

struct CreateCartItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("cart_items")
            .id()
            .field("cart_id", .uuid, .required, .references("carts", "id", onDelete: .cascade))
            .field("product_id", .uuid, .required, .references("products", "id", onDelete: .cascade))
            .field("quantity", .int, .required)
            .field("added_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("cart_items").delete()
    }
}
