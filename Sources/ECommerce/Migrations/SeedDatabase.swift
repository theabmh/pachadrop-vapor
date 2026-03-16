import Fluent
import Vapor
import Foundation

struct SeedDatabase: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Create admin user with bcrypt-hashed password
        let adminUser = User(
            fullName: "Admin User",
            email: "admin@example.com",
            passwordHash: try Bcrypt.hash("admin123"),
            role: .admin
        )
        try await adminUser.save(on: database)

        // Create sample categories
        let electronicsCategory = Category(name: "Electronics", description: "Electronic devices and gadgets")
        try await electronicsCategory.save(on: database)

        let clothingCategory = Category(name: "Clothing", description: "Apparel and clothing items")
        try await clothingCategory.save(on: database)

        let booksCategory = Category(name: "Books", description: "Books and reading materials")
        try await booksCategory.save(on: database)

        // Create sample products
        let laptop = Product(
            name: "MacBook Pro",
            description: "High-performance laptop for professionals",
            price: 1299.99,
            stockQuantity: 50,
            categoryID: electronicsCategory.id ?? UUID(),
            imageUrls: ["https://via.placeholder.com/300?text=MacBook"]
        )
        try await laptop.save(on: database)

        let phone = Product(
            name: "iPhone 15",
            description: "Latest iPhone with advanced features",
            price: 999.99,
            stockQuantity: 100,
            categoryID: electronicsCategory.id ?? UUID(),
            imageUrls: ["https://via.placeholder.com/300?text=iPhone"]
        )
        try await phone.save(on: database)

        let tshirt = Product(
            name: "Cotton T-Shirt",
            description: "Comfortable and durable cotton t-shirt",
            price: 29.99,
            stockQuantity: 200,
            categoryID: clothingCategory.id ?? UUID(),
            imageUrls: ["https://via.placeholder.com/300?text=TShirt"]
        )
        try await tshirt.save(on: database)

        let book = Product(
            name: "Swift Programming",
            description: "Learn Swift programming from basics to advanced",
            price: 49.99,
            stockQuantity: 150,
            categoryID: booksCategory.id ?? UUID(),
            imageUrls: ["https://via.placeholder.com/300?text=Book"]
        )
        try await book.save(on: database)
    }

    func revert(on database: Database) async throws {
        try await OrderItem.query(on: database).delete()
        try await Order.query(on: database).delete()
        try await CartItem.query(on: database).delete()
        try await Cart.query(on: database).delete()
        try await Product.query(on: database).delete()
        try await Category.query(on: database).delete()
        try await User.query(on: database).delete()
    }
}
