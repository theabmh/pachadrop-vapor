import Vapor

struct CategoryResponse: Content {
    let id: UUID
    let name: String
    let description: String
    let createdAt: Date?

    init(from category: Category) {
        self.id = category.id ?? UUID()
        self.name = category.name
        self.description = category.description
        self.createdAt = category.createdAt
    }
}
