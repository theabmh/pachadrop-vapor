import Vapor

struct CategoryController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categories = routes.grouped("api", "categories")

        // Public endpoints
        categories.get(use: list)
        categories.get(":id", use: get)

        // Admin only endpoints
        let admin = categories.grouped(BearerAuthenticator())
            .grouped(RoleMiddleware(requiredRoles: [.admin]))
        admin.post(use: create)
        admin.put(":id", use: update)
        admin.delete(":id", use: delete)
    }

    func list(req: Request) async throws -> [Category] {
        try await Category.query(on: req.db).all()
    }

    func get(req: Request) async throws -> Category {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        return category
    }

    func create(req: Request) async throws -> Category {
        let createReq = try req.content.decode(CreateCategoryRequest.self)

        guard !createReq.name.isEmpty else {
            throw Abort(.badRequest, reason: "Category name is required")
        }

        let category = Category(name: createReq.name, description: createReq.description)
        try await category.save(on: req.db)

        return category
    }

    func update(req: Request) async throws -> Category {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        let updateReq = try req.content.decode(UpdateCategoryRequest.self)

        if let name = updateReq.name {
            category.name = name
        }
        if let description = updateReq.description {
            category.description = description
        }

        try await category.update(on: req.db)

        return category
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        // Check if category has products
        let products = try await Product.query(on: req.db).all()
        let productCount = products.filter { $0.$category.id == id }.count

        if productCount > 0 {
            throw Abort(.conflict, reason: "Cannot delete category with products")
        }

        try await category.delete(on: req.db)

        return .noContent
    }
}
