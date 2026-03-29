import Vapor
import Fluent

struct HomeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Optional auth: BearerAuthenticator populates req.auth if a valid token is present,
        // but does not require it — unauthenticated requests still proceed.
        let home = routes.grouped("api", "v1", "home")
            .grouped(BearerAuthenticator())
        home.get(use: index)
    }

    func index(req: Request) async throws -> BaseResponseModel<HomeResponse> {
        // Resolve cart item count for authenticated users, 0 otherwise
        let cartItemCount: Int
        if let user = req.auth.get(AppUser.self), let userId = user.id {
            if let cart = try await Cart.query(on: req.db)
                .filter(\.$user.$id == userId)
                .first(),
               let cartId = cart.id {
                cartItemCount = try await CartItem.query(on: req.db)
                    .filter(\.$cart.$id == cartId)
                    .count()
            } else {
                cartItemCount = 0
            }
        } else {
            cartItemCount = 0
        }

        // Fetch all categories with their products
        let categories = try await Category.query(on: req.db).all()

        var categoryList: [CategoryWithProducts] = []
        for category in categories {
            guard let categoryId = category.id else { continue }
            let products = try await Product.query(on: req.db)
                .filter(\.$category.$id == categoryId)
                .all()
            categoryList.append(CategoryWithProducts(
                id: categoryId,
                name: category.name,
                description: category.description,
                products: products.map { ProductResponse(from: $0) }
            ))
        }

        return .success(
            HomeResponse(cartItemCount: cartItemCount, categories: categoryList),
            message: "Home data retrieved successfully"
        )
    }
}
