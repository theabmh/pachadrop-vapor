import Vapor

struct OrderResponse: Content {
    struct Item: Content {
        let id: UUID
        let productId: UUID
        let productName: String
        let productPrice: Double
        let quantity: Int
        let subtotal: Double
    }

    let id: UUID
    let userId: UUID
    let total: Double
    let status: OrderStatus
    let items: [Item]
    let createdAt: Date?
    let updatedAt: Date?
}
