import Vapor
import Fluent

final class Cart: Model, Content {
    static let schema = "carts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID) {
        self.id = id
        self.$user.id = userID
    }
}

final class CartItem: Model, Content {
    static let schema = "cart_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "cart_id")
    var cart: Cart

    @Parent(key: "product_id")
    var product: Product

    @Field(key: "quantity")
    var quantity: Int

    @Timestamp(key: "added_at", on: .create)
    var addedAt: Date?

    init() {}

    init(id: UUID? = nil, cartID: UUID, productID: UUID, quantity: Int) {
        self.id = id
        self.$cart.id = cartID
        self.$product.id = productID
        self.quantity = quantity
    }
}

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
