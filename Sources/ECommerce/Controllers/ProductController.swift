import Vapor
import Fluent

struct ProductController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("api", "v1", "products")

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

    func list(req: Request) async throws -> BaseResponseModel<PaginatedData<ProductResponse>> {
        let page = req.query[Int.self, at: "page"] ?? 1
        let perPage = min(req.query[Int.self, at: "per_page"] ?? 20, 100)
        let categoryId = req.query[String.self, at: "category_id"]

        var query = Product.query(on: req.db)

        if let categoryId = categoryId, let uuid = UUID(uuidString: categoryId) {
            query = query.filter(\.$category.$id == uuid)
        }

        let total = try await query.count()
        let products = try await query
            .range(((page - 1) * perPage)..<((page - 1) * perPage + perPage))
            .all()

        let items = products.map { ProductResponse(from: $0) }
        let totalPages = max(1, Int(ceil(Double(total) / Double(perPage))))

        let paginated = PaginatedData(
            items: items,
            total: total,
            page: page,
            perPage: perPage,
            totalPages: totalPages
        )

        return .success(paginated, message: "Products retrieved successfully")
    }

    func get(req: Request) async throws -> BaseResponseModel<ProductResponse> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }

        return .success(ProductResponse(from: product), message: "Product retrieved successfully")
    }

    func create(req: Request) async throws -> BaseResponseModel<ProductResponse> {
        try CreateProductRequest.validate(content: req)
        let createReq = try req.content.decode(CreateProductRequest.self)

        guard createReq.price > 0 else {
            throw Abort(.badRequest, reason: "Price must be greater than 0")
        }
        guard createReq.stockQuantity >= 0 else {
            throw Abort(.badRequest, reason: "Stock quantity cannot be negative")
        }

        // Verify category exists
        guard try await Category.find(createReq.categoryId, on: req.db) != nil else {
            throw Abort(.badRequest, reason: "Category not found")
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

        return .created(ProductResponse(from: product), message: "Product created successfully")
    }

    func update(req: Request) async throws -> BaseResponseModel<ProductResponse> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
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

        return .success(ProductResponse(from: product), message: "Product updated successfully")
    }

    func delete(req: Request) async throws -> BaseResponseModel<EmptyData> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found")
        }

        try await product.delete(on: req.db)

        return .noContent(message: "Product deleted successfully")
    }
}
