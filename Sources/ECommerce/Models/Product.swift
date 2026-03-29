import Vapor
import Fluent

final class Product: Model, Content {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Field(key: "price")
    var price: Double

    @Field(key: "stock_quantity")
    var stockQuantity: Int

    @Parent(key: "category_id")
    var category: Category

    @Field(key: "image_urls")
    var imageUrls: [String]

    @OptionalField(key: "subtitle")
    var subtitle: String?

    @OptionalField(key: "detail_description")
    var detailDescription: String?

    @OptionalField(key: "variant")
    var variant: String?

    @OptionalField(key: "emoji")
    var emoji: String?

    @OptionalField(key: "card_tint_hex")
    var cardTintHex: String?

    @OptionalField(key: "image_url")
    var imageURL: String?

    @OptionalField(key: "savings_percentage")
    var savingsPercentage: Int?

    @OptionalField(key: "delivery_info")
    var deliveryInfo: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        description: String,
        price: Double,
        stockQuantity: Int,
        categoryID: UUID,
        imageUrls: [String] = [],
        subtitle: String? = nil,
        detailDescription: String? = nil,
        variant: String? = nil,
        emoji: String? = nil,
        cardTintHex: String? = nil,
        imageURL: String? = nil,
        savingsPercentage: Int? = nil,
        deliveryInfo: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.stockQuantity = stockQuantity
        self.$category.id = categoryID
        self.imageUrls = imageUrls
        self.subtitle = subtitle
        self.detailDescription = detailDescription
        self.variant = variant
        self.emoji = emoji
        self.cardTintHex = cardTintHex
        self.imageURL = imageURL
        self.savingsPercentage = savingsPercentage
        self.deliveryInfo = deliveryInfo
    }
}

