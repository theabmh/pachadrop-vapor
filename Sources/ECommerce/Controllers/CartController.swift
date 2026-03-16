import Vapor

struct CartController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cart = routes.grouped("api", "cart")
            .grouped(BearerAuthenticator())

        cart.get(use: getCart)
        cart.post("items", use: addItem)
        cart.put("items", ":id", use: updateItem)
        cart.delete("items", ":id", use: removeItem)
        cart.delete(use: clearCart)
    }

    func getCart(req: Request) async throws -> CartResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        // Get or create cart
        var cart = try await Cart.query(on: req.db).all()
            .first { $0.$user.id == userId }

        if cart == nil {
            let newCart = Cart(userID: userId)
            try await newCart.save(on: req.db)
            cart = newCart
        }

        guard let cart = cart else {
            throw Abort(.notFound)
        }

        // Get cart items
        let items = try await CartItem.query(on: req.db).all()
            .filter { $0.$cart.id == cart.id ?? UUID() }

        var cartItems: [CartResponse.Item] = []
        var total: Double = 0

        for item in items {
            if let product = try await Product.find(item.$product.id, on: req.db) {
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
        }

        return CartResponse(
            id: cart.id ?? UUID(),
            items: cartItems,
            total: total,
            createdAt: cart.createdAt,
            updatedAt: cart.updatedAt
        )
    }

    func addItem(req: Request) async throws -> CartResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        let addReq = try req.content.decode(AddCartItemRequest.self)

        guard addReq.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than 0")
        }

        // Get or create cart
        var cart = try await Cart.query(on: req.db).all()
            .first { $0.$user.id == userId }

        if cart == nil {
            let newCart = Cart(userID: userId)
            try await newCart.save(on: req.db)
            cart = newCart
        }

        guard let cart = cart else {
            throw Abort(.notFound)
        }

        // Check if product exists and has stock
        guard let product = try await Product.find(addReq.productId, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }

        guard product.stockQuantity >= addReq.quantity else {
            throw Abort(.badRequest, reason: "Not enough stock available")
        }

        // Check if item already exists
        let cartId = cart.id ?? UUID()
        if let existingItem = try await CartItem.query(on: req.db).all()
            .first(where: { $0.$cart.id == cartId && $0.$product.id == addReq.productId }) {
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

    func updateItem(req: Request) async throws -> CartResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid item ID")
        }

        let updateReq = try req.content.decode(UpdateCartItemRequest.self)

        guard updateReq.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than 0")
        }

        guard let cart = try await Cart.query(on: req.db).all()
            .first(where: { $0.$user.id == userId }) else {
            throw Abort(.notFound)
        }

        guard let cartItem = try await CartItem.find(itemId, on: req.db) else {
            throw Abort(.notFound)
        }

        guard cartItem.$cart.id == cart.id ?? UUID() else {
            throw Abort(.forbidden)
        }

        if let product = try await Product.find(cartItem.$product.id, on: req.db) {
            guard product.stockQuantity >= updateReq.quantity else {
                throw Abort(.badRequest, reason: "Not enough stock available")
            }
        }

        cartItem.quantity = updateReq.quantity
        try await cartItem.update(on: req.db)

        return try await getCart(req: req)
    }

    func removeItem(req: Request) async throws -> CartResponse {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid item ID")
        }

        guard let cart = try await Cart.query(on: req.db).all()
            .first(where: { $0.$user.id == userId }) else {
            throw Abort(.notFound)
        }

        guard let cartItem = try await CartItem.find(itemId, on: req.db) else {
            throw Abort(.notFound)
        }

        guard cartItem.$cart.id == cart.id ?? UUID() else {
            throw Abort(.forbidden)
        }

        try await cartItem.delete(on: req.db)

        return try await getCart(req: req)
    }

    func clearCart(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(AppUser.self) else {
            throw Abort(.unauthorized)
        }

        guard let userId = user.id else {
            throw Abort(.unauthorized)
        }

        guard let cart = try await Cart.query(on: req.db).all()
            .first(where: { $0.$user.id == userId }) else {
            throw Abort(.notFound)
        }

        let cartId = cart.id ?? UUID()
        let itemsToDelete = try await CartItem.query(on: req.db).all()
            .filter { $0.$cart.id == cartId }

        for item in itemsToDelete {
            try await item.delete(on: req.db)
        }

        return .noContent
    }
}
