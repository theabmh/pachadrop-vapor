import Vapor

struct ProductResponse: Content {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let stockQuantity: Int
    let categoryId: UUID
    let imageUrls: [String]
    let subtitle: String?
    let detailDescription: String?
    let variant: String?
    let emoji: String?
    let cardTintHex: String?
    let imageURL: String?
    let savingsPercentage: Int?
    let deliveryInfo: String?
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
        self.subtitle = product.subtitle
        self.detailDescription = product.detailDescription
        self.variant = product.variant
        self.emoji = product.emoji
        self.cardTintHex = product.cardTintHex
        self.imageURL = product.imageURL
        self.savingsPercentage = product.savingsPercentage
        self.deliveryInfo = product.deliveryInfo
        self.createdAt = product.createdAt
        self.updatedAt = product.updatedAt
    }
}

struct CreateCategoryRequest: Content, Validatable {
    let name: String
    let description: String

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty, customFailureDescription: "Category name is required")
    }
}

struct UpdateCategoryRequest: Content {
    let name: String?
    let description: String?
}

struct CreateProductRequest: Content, Validatable {
    let name: String
    let description: String
    let price: Double
    let stockQuantity: Int
    let categoryId: UUID
    let imageUrls: [String]?
    let subtitle: String?
    let detailDescription: String?
    let variant: String?
    let emoji: String?
    let cardTintHex: String?
    let imageURL: String?
    let savingsPercentage: Int?
    let deliveryInfo: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case stockQuantity = "stock_quantity"
        case categoryId = "category_id"
        case imageUrls = "image_urls"
        case subtitle
        case detailDescription = "detail_description"
        case variant
        case emoji
        case cardTintHex = "card_tint_hex"
        case imageURL = "image_url"
        case savingsPercentage = "savings_percentage"
        case deliveryInfo = "delivery_info"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty, customFailureDescription: "Product name is required")
        validations.add("price", as: Double.self, is: .range(0.01...), customFailureDescription: "Price must be greater than 0")
        validations.add("stock_quantity", as: Int.self, is: .range(0...), customFailureDescription: "Stock quantity cannot be negative")
    }
}

struct UpdateProductRequest: Content {
    let name: String?
    let description: String?
    let price: Double?
    let stockQuantity: Int?
    let imageUrls: [String]?
    let subtitle: String?
    let detailDescription: String?
    let variant: String?
    let emoji: String?
    let cardTintHex: String?
    let imageURL: String?
    let savingsPercentage: Int?
    let deliveryInfo: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case stockQuantity = "stock_quantity"
        case imageUrls = "image_urls"
        case subtitle
        case detailDescription = "detail_description"
        case variant
        case emoji
        case cardTintHex = "card_tint_hex"
        case imageURL = "image_url"
        case savingsPercentage = "savings_percentage"
        case deliveryInfo = "delivery_info"
    }
}
