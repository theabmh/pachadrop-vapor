import Vapor
import JWT

struct BearerAuthenticator: AsyncBearerAuthenticator {
    typealias User = AppUser

    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        do {
            let userPayload = try request.jwt.verify(bearer.token, as: UserPayload.self)
            let userId = UUID(uuidString: userPayload.subject.value)
            let appUser = AppUser(
                id: userId,
                email: "",
                role: userPayload.role
            )
            request.auth.login(appUser)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }
    }
}

struct AppUser: Authenticatable {
    let id: UUID?
    let email: String
    let role: UserRole
}

struct RoleMiddleware: AsyncMiddleware {
    let requiredRoles: [UserRole]

    init(requiredRoles: [UserRole]) {
        self.requiredRoles = requiredRoles
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(AppUser.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }

        guard requiredRoles.contains(user.role) else {
            throw Abort(.forbidden, reason: "User does not have required role")
        }

        return try await next.respond(to: request)
    }
}
