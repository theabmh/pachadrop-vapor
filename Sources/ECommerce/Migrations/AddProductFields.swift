import Fluent

struct AddProductFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("products")
            .field("subtitle", .string)
            .field("detail_description", .string)
            .field("variant", .string)
            .field("emoji", .string)
            .field("card_tint_hex", .string)
            .field("image_url", .string)
            .field("savings_percentage", .int)
            .field("delivery_info", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("products")
            .deleteField("subtitle")
            .deleteField("detail_description")
            .deleteField("variant")
            .deleteField("emoji")
            .deleteField("card_tint_hex")
            .deleteField("image_url")
            .deleteField("savings_percentage")
            .deleteField("delivery_info")
            .update()
    }
}
