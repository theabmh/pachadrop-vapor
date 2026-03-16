import Vapor

struct RegisterRequest: Content {
    let fullName: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case password
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let userId: UUID
    let email: String
    let fullName: String
    let role: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case fullName = "full_name"
        case role
        case token
    }
}

struct ErrorResponse: Content {
    let error: String
    let message: String?
}
