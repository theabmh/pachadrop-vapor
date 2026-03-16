import Vapor
import Fluent

struct CartController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cart = routes.grouped("api", "v1", "cart")
            .grouped(BearerAuthenticator())

        cart.get(use: getCart)
        cart.post("items", use: addItem)
        cart.put("items", ":id", use: updateItem)
        cart.delete("items", ":id", use: removeItem)
        cart.delete(use: clearCart)
    }

    func getCart(req: Request) async throws -> BaseResponseModel<CartResponse> {
        let userId = try getUserId(req: req)

        // Get or create cart using DB filter
        var cart = try await Cart.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()

        if cart == nil {
            let newCart = Cart(userID: userId)
            try await newCart.save(on: req.db)
            cart = newCart
        }

        guard let cart = cart else {
            throw Abort(.internalServerError, reason: "Failed to create cart")
        }

        let cartId = cart.id ?? UUID()

        // Get cart items with eager product loading
        let items = try await CartItem.query(on: req.db)
            .filter(\.$cart.$id == cartId)
            .with(\.$product)
            .all()

        var cartItems: [CartResponse.Item] = []
        var total: Double = 0

        for item in items {
            let product = item.product
            let subtotal = product.price * Double(item.quantity)
            total += subtotal
            cartItems.append(
                CartResponse.Item(
                    id: item.id ?? UUID(),
                    productId: product.id ?? UUID(),
                    productName: product.name,
                    productPrice: product.price,
                    quantity: item.quantity,
                    subtotal: subtotal
                )
            )
        }

        let response = CartResponse(
            id: cart.id ?? UUID(),
            items: cartItems,
            total: total,
            createdAt: cart.createdAt,
            updatedAt: cart.updatedAt
        )

        return .success(response, message: "Cart retrieved successfully")
    }

    func addItem(req: Request) async throws -> BaseResponseModel<CartResponse> {
        let userId = try getUserId(req: req)
        let addReq = try req.content.decode(AddCartItemRequest.self)

        guard addReq.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than 0")
        }

        // Get or create cart
        var cart = try await Cart.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()

        if cart == nil {
            let newCart = Cart(userID: userId)
            try await newCart.save(on: req.db)
            cart = newCart
        }

        guard let cart = cart else {
            throw Abort(.internalServerError, reason: "Failed to create cart")
        }

        let cartId = cart.id ?? UUID()

        // Check if product exists and has stock
        guard let product = try await Product.find(addReq.productId, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }

        guard product.stockQuantity >= addReq.quantity else {
            throw Abort(.badRequest, reason: "Not enough stock available")
        }

        // Check if item already exists using DB filter
        if let existingItem = try await CartItem.query(on: req.db)
            .filter(\.$cart.$id == cartId)
            .filter(\.$product.$id == addReq.productId)
            .first() {
            existingItem.quantity += addReq.quantity
            try await existingItem.update(on: req.db)
        } else {
            let cartItem = CartItem(
                cartID: cartId,
                productID: addReq.productId,
                quantity: addReq.quantity
            )
            try await cartItem.save(on: req.db)
        }

        return try await getCart(req: req)
    }

    func updateItem(req: Request) async throws -> BaseResponseModel<CartResponse> {
        let userId = try getUserId(req: req)

        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid item ID")
        }

        let updateReq = try req.content.decode(UpdateCartItemRequest.self)

        guard updateReq.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than 0")
        }

        guard let cart = try await Cart.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Cart not found")
        }

        guard let cartItem = try await CartItem.find(itemId, on: req.db) else {
            throw Abort(.notFound, reason: "Cart item not found")
        }

        guard cartItem.$cart.id == cart.id else {
            throw Abort(.forbidden, reason: "This item does not belong to your cart")
        }

        // Check stock
        if let product = try await Product.find(cartItem.$product.id, on: req.db) {
            guard product.stockQuantity >= updateReq.quantity else {
                throw Abort(.badRequest, reason: "Not enough stock available")
            }
        }

        cartItem.quantity = updateReq.quantity
        try await cartItem.update(on: req.db)

        return try await getCart(req: req)
    }

    func removeItem(req: Request) async throws -> BaseResponseModel<CartResponse> {
        let userId = try getUserId(req: req)

        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid item ID")
        }

        guard let cart = try await Cart.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Cart not found")
        }

        guard let cartItem = try await CartItem.find(itemId, on: req.db) else {
            throw Abort(.notFound, reason: "Cart item not found")
        }

        guard cartItem.$cart.id == cart.id else {
            throw Abort(.forbidden, reason: "This item does not belong to your cart")
        }

        try await cartItem.delete(on: req.db)

        return try await getCart(req: req)
    }

    func clearCart(req: Request) async throws -> BaseResponseModel<EmptyData> {
        let userId = try getUserId(req: req)

        guard let cart = try await Cart.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Cart not found")
        }

        let cartId = cart.id ?? UUID()

        // Batch delete using DB query
        try await CartItem.query(on: req.db)
            .filter(\.$cart.$id == cartId)
            .delete()

        return .noContent(message: "Cart cleared successfully")
    }

    // MARK: - Helpers

    private func getUserId(req: Request) throws -> UUID {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        guard let userId = user.id else {
            throw Abort(.unauthorized, reason: "Invalid user session")
        }
        return userId
    }
}
