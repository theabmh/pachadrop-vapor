import Vapor

struct RegisterRequest: Content, Validatable {
    let fullName: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case password
    }

    static func validations(_ validations: inout Validations) {
        validations.add("full_name", as: String.self, is: !.empty, customFailureDescription: "Full name is required")
        validations.add("email", as: String.self, is: .email, customFailureDescription: "A valid email is required")
        validations.add("password", as: String.self, is: .count(6...), customFailureDescription: "Password must be at least 6 characters")
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
