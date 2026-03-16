import Vapor

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

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case stockQuantity = "stock_quantity"
        case categoryId = "category_id"
        case imageUrls = "image_urls"
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

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case stockQuantity = "stock_quantity"
        case imageUrls = "image_urls"
    }
}
