import Vapor

struct ProductController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("api", "products")

        // Public endpoints
        products.get(use: list)
        products.get(":id", use: get)

        // Admin only endpoints
        let admin = products.grouped(BearerAuthenticator())
            .grouped(RoleMiddleware(requiredRoles: [.admin]))
        admin.post(use: create)
        admin.put(":id", use: update)
        admin.delete(":id", use: delete)
    }

    func list(req: Request) async throws -> [ProductResponse] {
        let limit = req.query[Int.self, at: "limit"] ?? 20
        let offset = req.query[Int.self, at: "offset"] ?? 0
        let categoryId = req.query[String.self, at: "category_id"]

        var products = try await Product.query(on: req.db).all()

        if let categoryId = categoryId, let uuid = UUID(uuidString: categoryId) {
            products = products.filter { $0.$category.id == uuid }
        }

        // Apply pagination
        let paginatedProducts = Array(products.dropFirst(offset).prefix(limit))

        return paginatedProducts.map { ProductResponse(from: $0) }
    }

    func get(req: Request) async throws -> ProductResponse {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        return ProductResponse(from: product)
    }

    func create(req: Request) async throws -> ProductResponse {
        let createReq = try req.content.decode(CreateProductRequest.self)

        guard !createReq.name.isEmpty else {
            throw Abort(.badRequest, reason: "Product name is required")
        }
        guard createReq.price > 0 else {
            throw Abort(.badRequest, reason: "Price must be greater than 0")
        }
        guard createReq.stockQuantity >= 0 else {
            throw Abort(.badRequest, reason: "Stock quantity cannot be negative")
        }

        let product = Product(
            name: createReq.name,
            description: createReq.description,
            price: createReq.price,
            stockQuantity: createReq.stockQuantity,
            categoryID: createReq.categoryId,
            imageUrls: createReq.imageUrls ?? []
        )

        try await product.save(on: req.db)

        return ProductResponse(from: product)
    }

    func update(req: Request) async throws -> ProductResponse {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        let updateReq = try req.content.decode(UpdateProductRequest.self)

        if let name = updateReq.name {
            product.name = name
        }
        if let description = updateReq.description {
            product.description = description
        }
        if let price = updateReq.price {
            guard price > 0 else {
                throw Abort(.badRequest, reason: "Price must be greater than 0")
            }
            product.price = price
        }
        if let stockQuantity = updateReq.stockQuantity {
            guard stockQuantity >= 0 else {
                throw Abort(.badRequest, reason: "Stock quantity cannot be negative")
            }
            product.stockQuantity = stockQuantity
        }
        if let imageUrls = updateReq.imageUrls {
            product.imageUrls = imageUrls
        }

        try await product.update(on: req.db)

        return ProductResponse(from: product)
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        try await product.delete(on: req.db)

        return .noContent
    }
}
