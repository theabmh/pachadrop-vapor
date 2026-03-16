import Vapor

struct CartResponse: Content {
    struct Item: Content {
        let id: UUID
        let productId: UUID
        let productName: String
        let productPrice: Double
        let quantity: Int
        let subtotal: Double
    }

    let id: UUID
    let items: [Item]
    let total: Double
    let createdAt: Date?
    let updatedAt: Date?
}

struct AddCartItemRequest: Content {
    let productId: UUID
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
    }
}

struct UpdateCartItemRequest: Content {
    let quantity: Int
}

struct CheckoutRequest: Content {
    let shippingAddress: String?

    enum CodingKeys: String, CodingKey {
        case shippingAddress = "shipping_address"
    }
}

struct PaymentRequest: Content {
    let paymentMethod: String

    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
    }
}
