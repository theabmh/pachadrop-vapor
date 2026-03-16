import Vapor
import Fluent

struct CategoryController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categories = routes.grouped("api", "v1", "categories")

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

    func list(req: Request) async throws -> BaseResponseModel<[CategoryResponse]> {
        let categories = try await Category.query(on: req.db).all()
        let responses = categories.map { CategoryResponse(from: $0) }
        return .success(responses, message: "Categories retrieved successfully")
    }

    func get(req: Request) async throws -> BaseResponseModel<CategoryResponse> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Category not found")
        }

        return .success(CategoryResponse(from: category), message: "Category retrieved successfully")
    }

    func create(req: Request) async throws -> BaseResponseModel<CategoryResponse> {
        try CreateCategoryRequest.validate(content: req)
        let createReq = try req.content.decode(CreateCategoryRequest.self)

        let category = Category(name: createReq.name, description: createReq.description)
        try await category.save(on: req.db)

        return .created(CategoryResponse(from: category), message: "Category created successfully")
    }

    func update(req: Request) async throws -> BaseResponseModel<CategoryResponse> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Category not found")
        }

        let updateReq = try req.content.decode(UpdateCategoryRequest.self)

        if let name = updateReq.name {
            category.name = name
        }
        if let description = updateReq.description {
            category.description = description
        }

        try await category.update(on: req.db)

        return .success(CategoryResponse(from: category), message: "Category updated successfully")
    }

    func delete(req: Request) async throws -> BaseResponseModel<EmptyData> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid category ID")
        }

        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Category not found")
        }

        // Check if category has products using DB filter
        let productCount = try await Product.query(on: req.db)
            .filter(\.$category.$id == id)
            .count()

        if productCount > 0 {
            throw Abort(.conflict, reason: "Cannot delete category with \(productCount) associated products")
        }

        try await category.delete(on: req.db)

        return .noContent(message: "Category deleted successfully")
    }
}
