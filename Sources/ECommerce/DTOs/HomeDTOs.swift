import Vapor

struct HomeResponse: Content {
    let cartItemCount: Int
    let categories: [CategoryWithProducts]
}

struct CategoryWithProducts: Content {
    let id: UUID
    let name: String
    let description: String
    let products: [ProductResponse]
}
