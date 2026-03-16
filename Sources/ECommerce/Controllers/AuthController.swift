import Vapor
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
    }

    func register(req: Request) async throws -> AuthResponse {
        let registerReq = try req.content.decode(RegisterRequest.self)

        // Validate input
        guard !registerReq.fullName.isEmpty else {
            throw Abort(.badRequest, reason: "Full name is required")
        }
        guard !registerReq.email.isEmpty else {
            throw Abort(.badRequest, reason: "Email is required")
        }
        guard !registerReq.password.isEmpty else {
            throw Abort(.badRequest, reason: "Password is required")
        }

        // Check if email already exists
        let existingUser = try await User.query(on: req.db).all()
            .first { $0.email == registerReq.email }

        if existingUser != nil {
            throw Abort(.conflict, reason: "Email already registered")
        }

        // Create new user
        let passwordHash = registerReq.password // In production, use proper bcrypt hashing
        let user = User(
            fullName: registerReq.fullName,
            email: registerReq.email,
            passwordHash: passwordHash,
            role: .customer
        )

        try await user.save(on: req.db)

        // Create JWT token
        let expirationDate = Date().addingTimeInterval(86400 * 7) // 7 days
        let payload = UserPayload(
            subject: .init(value: user.id?.uuidString ?? ""),
            expiration: .init(value: expirationDate),
            role: .customer
        )
        let token = try req.jwt.sign(payload)

        return AuthResponse(
            userId: user.id ?? UUID(),
            email: user.email,
            fullName: user.fullName,
            role: user.role.rawValue,
            token: token
        )
    }

    func login(req: Request) async throws -> AuthResponse {
        let loginReq = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db).all()
            .first(where: { $0.email == loginReq.email }) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // Verify password
        guard loginReq.password == user.passwordHash else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // Create JWT token
        let expirationDate = Date().addingTimeInterval(86400 * 7)
        let payload = UserPayload(
            subject: .init(value: user.id?.uuidString ?? ""),
            expiration: .init(value: expirationDate),
            role: user.role
        )
        let token = try req.jwt.sign(payload)

        return AuthResponse(
            userId: user.id ?? UUID(),
            email: user.email,
            fullName: user.fullName,
            role: user.role.rawValue,
            token: token
        )
    }
}
