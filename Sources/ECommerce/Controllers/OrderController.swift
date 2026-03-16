import Vapor

struct OrderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let orders = routes.grouped("api", "orders")
            .grouped(BearerAuthenticator())

        orders.get(use: list)
        orders.get(":id", use: get)
        orders.post("checkout", use: checkout)
        orders.post(":id", "pay", use: pay)
    }

    func list(req: Request) async throws -> [OrderResponse] {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        var orders = try await Order.query(on: req.db).all()
        if user.role == .customer {
            orders = orders.filter { $0.$user.id == userId }
        }

        var responses: [OrderResponse] = []
        let allItems = try await OrderItem.query(on: req.db).all()

        for order in orders {
            let orderId = order.id ?? UUID()
            let items = allItems.filter { $0.$order.id == orderId }

            let orderItems = items.map { item in
                OrderResponse.Item(
                    id: item.id ?? UUID(),
                    productId: item.productId,
                    productName: item.productName,
                    productPrice: item.productPrice,
                    quantity: item.quantity,
                    subtotal: item.subtotal
                )
            }

            responses.append(
                OrderResponse(
                    id: order.id ?? UUID(),
                    userId: order.$user.id,
                    total: order.total,
                    status: order.status,
                    items: orderItems,
                    createdAt: order.createdAt,
                    updatedAt: order.updatedAt
                )
            )
        }

        return responses
    }

    func get(req: Request) async throws -> OrderResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let orderId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }

        guard let order = try await Order.find(orderId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Check authorization
        if user.role == .customer && order.$user.id != userId {
            throw Abort(.forbidden)
        }

        let allItems = try await OrderItem.query(on: req.db).all()
        let items = allItems.filter { $0.$order.id == orderId }

        let orderItems = items.map { item in
            OrderResponse.Item(
                id: item.id ?? UUID(),
                productId: item.productId,
                productName: item.productName,
                productPrice: item.productPrice,
                quantity: item.quantity,
                subtotal: item.subtotal
            )
        }

        return OrderResponse(
            id: order.id ?? UUID(),
            userId: order.$user.id,
            total: order.total,
            status: order.status,
            items: orderItems,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )
    }

    func checkout(req: Request) async throws -> OrderResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let cart = try await Cart.query(on: req.db).all()
            .first(where: { $0.$user.id == userId }) else {
            throw Abort(.badRequest, reason: "Cart not found")
        }

        let cartId = cart.id ?? UUID()
        let allCartItems = try await CartItem.query(on: req.db).all()
        let cartItems = allCartItems.filter { $0.$cart.id == cartId }

        guard !cartItems.isEmpty else {
            throw Abort(.badRequest, reason: "Cart is empty")
        }

        // Calculate total and create order
        var total: Double = 0
        var orderItems: [OrderItem] = []

        for cartItem in cartItems {
            guard let product = try await Product.find(cartItem.$product.id, on: req.db) else {
                throw Abort(.notFound, reason: "Product not found")
            }

            guard product.stockQuantity >= cartItem.quantity else {
                throw Abort(.badRequest, reason: "Not enough stock for \(product.name)")
            }

            // Reduce stock
            product.stockQuantity -= cartItem.quantity
            try await product.update(on: req.db)

            // Create order item
            let orderItem = OrderItem(
                orderID: UUID(), // Will be set after order creation
                productId: product.id ?? UUID(),
                productName: product.name,
                productPrice: product.price,
                quantity: cartItem.quantity
            )
            total += orderItem.subtotal
            orderItems.append(orderItem)
        }

        // Create order
        let order = Order(userID: userId, total: total, status: .pending)
        try await order.save(on: req.db)

        // Save order items
        for var item in orderItems {
            item.$order.id = order.id ?? UUID()
            try await item.save(on: req.db)
        }

        // Clear cart
        for item in cartItems {
            try await item.delete(on: req.db)
        }

        let finalOrderItems = orderItems.map { item in
            OrderResponse.Item(
                id: item.id ?? UUID(),
                productId: item.productId,
                productName: item.productName,
                productPrice: item.productPrice,
                quantity: item.quantity,
                subtotal: item.subtotal
            )
        }

        return OrderResponse(
            id: order.id ?? UUID(),
            userId: userId,
            total: order.total,
            status: order.status,
            items: finalOrderItems,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )
    }

    func pay(req: Request) async throws -> OrderResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let orderId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }

        guard let order = try await Order.find(orderId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Check authorization
        if user.role == .customer && order.$user.id != userId {
            throw Abort(.forbidden)
        }

        guard order.status == .pending else {
            throw Abort(.badRequest, reason: "Order is not in pending status")
        }

        let paymentReq = try req.content.decode(PaymentRequest.self)

        guard !paymentReq.paymentMethod.isEmpty else {
            throw Abort(.badRequest, reason: "Payment method is required")
        }

        // Update order status to paid
        order.status = .paid
        try await order.update(on: req.db)

        let allItems = try await OrderItem.query(on: req.db).all()
        let items = allItems.filter { $0.$order.id == orderId }

        let orderItems = items.map { item in
            OrderResponse.Item(
                id: item.id ?? UUID(),
                productId: item.productId,
                productName: item.productName,
                productPrice: item.productPrice,
                quantity: item.quantity,
                subtotal: item.subtotal
            )
        }

        return OrderResponse(
            id: order.id ?? UUID(),
            userId: order.$user.id,
            total: order.total,
            status: order.status,
            items: orderItems,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )
    }
}
