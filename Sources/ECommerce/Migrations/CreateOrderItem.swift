import Fluent

struct CreateOrderItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("order_items")
            .id()
            .field("order_id", .uuid, .required, .references("orders", "id", onDelete: .cascade))
            .field("product_id", .uuid, .required)
            .field("product_name", .string, .required)
            .field("product_price", .double, .required)
            .field("quantity", .int, .required)
            .field("subtotal", .double, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("order_items").delete()
    }
}
