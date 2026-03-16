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
            throw Abort(.unauthorized)
        }
    }
}

struct AppUser: Authenticatable {
    let id: UUID?
    let email: String
    let role: UserRole
}

final class RoleMiddleware: Middleware {
    let requiredRoles: [UserRole]

    init(requiredRoles: [UserRole]) {
        self.requiredRoles = requiredRoles
    }

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(AppUser.self) else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "User not authenticated"))
        }

        guard requiredRoles.contains(user.role) else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden, reason: "User does not have required role"))
        }

        return next.respond(to: request)
    }
}
