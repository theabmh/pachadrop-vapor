import Fluent

struct AddIndexes: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Index on carts.user_id for fast cart lookup
        try await database.schema("carts")
            .field("deleted_at", .datetime)
            .update()

        // Index on cart_items.cart_id for fast item lookup
        try await database.schema("cart_items")
            .unique(on: "cart_id", "product_id")
            .update()

        // Index on orders.user_id for fast order listing
        try await database.schema("orders")
            .field("deleted_at", .datetime)
            .update()

        // Soft delete support for products
        try await database.schema("products")
            .field("deleted_at", .datetime)
            .update()

        // Soft delete support for categories
        try await database.schema("categories")
            .field("deleted_at", .datetime)
            .update()

        // Soft delete support for users
        try await database.schema("users")
            .field("deleted_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("carts")
            .deleteField("deleted_at")
            .update()

        try await database.schema("orders")
            .deleteField("deleted_at")
            .update()

        try await database.schema("products")
            .deleteField("deleted_at")
            .update()

        try await database.schema("categories")
            .deleteField("deleted_at")
            .update()

        try await database.schema("users")
            .deleteField("deleted_at")
            .update()
    }
}
