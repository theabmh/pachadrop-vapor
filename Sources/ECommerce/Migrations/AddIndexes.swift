import Fluent

struct AddIndexes: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Unique constraint on cart_items (cart_id, product_id)
        try await database.schema("cart_items")
            .unique(on: "cart_id", "product_id")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("cart_items")
            .deleteUnique(on: "cart_id", "product_id")
            .update()
    }
}
