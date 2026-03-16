import Vapor
import Fluent

enum OrderStatus: String, Codable {
    case pending
    case paid
    case shipped
    case delivered
}

final class Order: Model, Content {
    static let schema = "orders"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "total")
    var total: Double

    @Field(key: "status")
    var status: OrderStatus

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        total: Double,
        status: OrderStatus = .pending
    ) {
        self.id = id
        self.$user.id = userID
        self.total = total
        self.status = status
    }
}

final class OrderItem: Model, Content {
    static let schema = "order_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    @Field(key: "product_id")
    var productId: UUID

    @Field(key: "product_name")
    var productName: String

    @Field(key: "product_price")
    var productPrice: Double

    @Field(key: "quantity")
    var quantity: Int

    @Field(key: "subtotal")
    var subtotal: Double

    init() {}

    init(
        id: UUID? = nil,
        orderID: UUID,
        productId: UUID,
        productName: String,
        productPrice: Double,
        quantity: Int
    ) {
        self.id = id
        self.$order.id = orderID
        self.productId = productId
        self.productName = productName
        self.productPrice = productPrice
        self.quantity = quantity
        self.subtotal = productPrice * Double(quantity)
    }
}

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
