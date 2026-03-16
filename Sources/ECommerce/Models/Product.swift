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

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        description: String,
        price: Double,
        stockQuantity: Int,
        categoryID: UUID,
        imageUrls: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.stockQuantity = stockQuantity
        self.$category.id = categoryID
        self.imageUrls = imageUrls
    }
}

struct ProductResponse: Content {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let stockQuantity: Int
    let categoryId: UUID
    let imageUrls: [String]
    let createdAt: Date?
    let updatedAt: Date?

    init(from product: Product) {
        self.id = product.id ?? UUID()
        self.name = product.name
        self.description = product.description
        self.price = product.price
        self.stockQuantity = product.stockQuantity
        self.categoryId = product.$category.id
        self.imageUrls = product.imageUrls
        self.createdAt = product.createdAt
        self.updatedAt = product.updatedAt
    }
}
