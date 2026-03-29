import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "v1", "auth")
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        auth.post("register", use: register)
        auth.post("login", use: login)
    }

    func register(req: Request) async throws -> BaseResponseModel<AuthResponse> {
        try RegisterRequest.validate(content: req)
        let registerReq = try req.content.decode(RegisterRequest.self)

        // Check if email already exists using DB filter
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == registerReq.email)
            .first()

        if existingUser != nil {
            throw Abort(.conflict, reason: "Email already registered")
        }

        // Hash password with bcrypt
        let passwordHash = try Bcrypt.hash(registerReq.password)
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

        let response = AuthResponse(
            userId: user.id ?? UUID(),
            email: user.email,
            fullName: user.fullName,
            role: user.role.rawValue,
            token: token
        )

        return .created(response, message: "Registration successful")
    }

    func login(req: Request) async throws -> BaseResponseModel<AuthResponse> {
        let loginReq = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginReq.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // Verify password with bcrypt
        guard let hash = user.passwordHash else {
            throw Abort(.unauthorized, reason: "This account uses Google Sign-In. Please use the Google login option.")
        }
        guard try Bcrypt.verify(loginReq.password, created: hash) else {
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

        let response = AuthResponse(
            userId: user.id ?? UUID(),
            email: user.email,
            fullName: user.fullName,
            role: user.role.rawValue,
            token: token
        )

        return .success(response, message: "Login successful")
    }
}
