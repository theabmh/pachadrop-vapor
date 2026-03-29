import Vapor
import Fluent
import JWT

struct GoogleAuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "v1", "auth")
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        auth.post("google", use: googleSignIn)
    }

    func googleSignIn(req: Request) async throws -> BaseResponseModel<AuthResponse> {
        try GoogleAuthRequest.validate(content: req)
        let body = try req.content.decode(GoogleAuthRequest.self)

        // Verify the Google ID token via JWKS (fetched and cached automatically by JWTKit)
        let googleToken: GoogleIdentityToken
        do {
            googleToken = try await req.jwt.google.verify(body.idToken)
        } catch {
            req.logger.warning("Google token verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Invalid or expired Google ID token")
        }

        // Email is optional in the token spec — guard it
        guard let email = googleToken.email else {
            throw Abort(.badRequest, reason: "Google account does not expose an email address")
        }

        // Only accept tokens where Google has verified the email
        guard googleToken.emailVerified?.value == true else {
            throw Abort(.unauthorized, reason: "Google account email is not verified")
        }

        let googleId = googleToken.subject.value

        // Build a display name from available claims
        let fullName = googleToken.name
            ?? [googleToken.givenName, googleToken.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .nilIfEmpty()
            ?? String(email.prefix(while: { $0 != "@" }))

        let user = try await findOrCreateUser(
            googleId: googleId,
            email: email,
            fullName: fullName,
            on: req.db
        )

        // Issue our own JWT — same payload structure as email/password login
        let expirationDate = Date().addingTimeInterval(86400 * 7) // 7 days
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

        return .success(response, message: "Google sign-in successful")
    }

    // MARK: - Find-or-create with account linking

    private func findOrCreateUser(
        googleId: String,
        email: String,
        fullName: String,
        on db: Database
    ) async throws -> User {

        // Case 1: Returning Google user — already linked
        if let existing = try await User.query(on: db)
            .filter(\.$googleId == googleId)
            .first() {
            return existing
        }

        // Case 2: Email/password account exists with same email — silently link
        // Safe to auto-link: Google already proved ownership of this email via verified token
        if let existing = try await User.query(on: db)
            .filter(\.$email == email)
            .first() {
            existing.googleId = googleId
            try await existing.save(on: db)
            return existing
        }

        // Case 3: Brand new user — create a Google-provider account (no password)
        let newUser = User(
            fullName: fullName,
            email: email,
            passwordHash: nil,
            role: .customer,
            authProvider: .google,
            googleId: googleId
        )
        try await newUser.save(on: db)
        return newUser
    }
}

private extension String {
    func nilIfEmpty() -> String? {
        isEmpty ? nil : self
    }
}
