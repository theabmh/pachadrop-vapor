import Vapor
import Fluent

struct OrderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let orders = routes.grouped("api", "v1", "orders")
            .grouped(BearerAuthenticator())

        orders.get(use: list)
        orders.get(":id", use: get)
        orders.post("checkout", use: checkout)
        orders.post(":id", "pay", use: pay)
    }

    func list(req: Request) async throws -> BaseResponseModel<[OrderResponse]> {
        let user = try getUser(req: req)
        let userId = try getUserId(from: user)

        // Use DB-level filtering based on role
        var query = Order.query(on: req.db)
        if user.role == .customer {
            query = query.filter(\.$user.$id == userId)
        }

        let orders = try await query.all()

        var responses: [OrderResponse] = []
        for order in orders {
            let orderId = order.id ?? UUID()
            let items = try await OrderItem.query(on: req.db)
                .filter(\.$order.$id == orderId)
                .all()

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
                    id: orderId,
                    userId: order.$user.id,
                    total: order.total,
                    status: order.status,
                    items: orderItems,
                    createdAt: order.createdAt,
                    updatedAt: order.updatedAt
                )
            )
        }

        return .success(responses, message: "Orders retrieved successfully")
    }

    func get(req: Request) async throws -> BaseResponseModel<OrderResponse> {
        let user = try getUser(req: req)
        let userId = try getUserId(from: user)

        guard let orderId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }

        guard let order = try await Order.find(orderId, on: req.db) else {
            throw Abort(.notFound, reason: "Order not found")
        }

        // Check authorization
        if user.role == .customer && order.$user.id != userId {
            throw Abort(.forbidden, reason: "You do not have access to this order")
        }

        let items = try await OrderItem.query(on: req.db)
            .filter(\.$order.$id == orderId)
            .all()

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

        let response = OrderResponse(
            id: orderId,
            userId: order.$user.id,
            total: order.total,
            status: order.status,
            items: orderItems,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )

        return .success(response, message: "Order retrieved successfully")
    }

    func checkout(req: Request) async throws -> BaseResponseModel<OrderResponse> {
        let userId = try getUserId(from: try getUser(req: req))

        // Wrap everything in a transaction for atomicity
        return try await req.db.transaction { db in
            guard let cart = try await Cart.query(on: db)
                .filter(\.$user.$id == userId)
                .first() else {
                throw Abort(.badRequest, reason: "Cart not found")
            }

            let cartId = cart.id ?? UUID()
            let cartItems = try await CartItem.query(on: db)
                .filter(\.$cart.$id == cartId)
                .with(\.$product)
                .all()

            guard !cartItems.isEmpty else {
                throw Abort(.badRequest, reason: "Cart is empty")
            }

            // Calculate total and validate stock
            var total: Double = 0
            var orderItems: [OrderItem] = []

            for cartItem in cartItems {
                let product = cartItem.product

                guard product.stockQuantity >= cartItem.quantity else {
                    throw Abort(.badRequest, reason: "Not enough stock for \(product.name)")
                }

                // Reduce stock
                product.stockQuantity -= cartItem.quantity
                try await product.update(on: db)

                let orderItem = OrderItem(
                    orderID: UUID(), // Placeholder, set after order creation
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
            try await order.save(on: db)

            let orderId = order.id ?? UUID()

            // Save order items
            for item in orderItems {
                item.$order.id = orderId
                try await item.save(on: db)
            }

            // Clear cart items
            try await CartItem.query(on: db)
                .filter(\.$cart.$id == cartId)
                .delete()

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

            let response = OrderResponse(
                id: orderId,
                userId: userId,
                total: order.total,
                status: order.status,
                items: finalOrderItems,
                createdAt: order.createdAt,
                updatedAt: order.updatedAt
            )

            return BaseResponseModel.created(response, message: "Order placed successfully")
        }
    }

    func pay(req: Request) async throws -> BaseResponseModel<OrderResponse> {
        let user = try getUser(req: req)
        let userId = try getUserId(from: user)

        guard let orderId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }

        guard let order = try await Order.find(orderId, on: req.db) else {
            throw Abort(.notFound, reason: "Order not found")
        }

        // Check authorization
        if user.role == .customer && order.$user.id != userId {
            throw Abort(.forbidden, reason: "You do not have access to this order")
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

        let items = try await OrderItem.query(on: req.db)
            .filter(\.$order.$id == orderId)
            .all()

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

        let response = OrderResponse(
            id: orderId,
            userId: order.$user.id,
            total: order.total,
            status: order.status,
            items: orderItems,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt
        )

        return .success(response, message: "Payment successful")
    }

    // MARK: - Helpers

    private func getUser(req: Request) throws -> AppUser {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        return user
    }

    private func getUserId(from user: AppUser) throws -> UUID {
        guard let userId = user.id else {
            throw Abort(.unauthorized, reason: "Invalid user session")
        }
        return userId
    }
}
