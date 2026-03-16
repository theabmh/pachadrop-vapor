import Vapor

struct CreateCategoryRequest: Content {
    let name: String
    let description: String
}

struct UpdateCategoryRequest: Content {
    let name: String?
    let description: String?
}

struct CreateProductRequest: Content {
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
