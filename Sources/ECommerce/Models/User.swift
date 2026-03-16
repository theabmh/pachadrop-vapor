import Vapor
import Fluent
import JWT

enum UserRole: String, Codable {
    case admin
    case customer
}

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "full_name")
    var fullName: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "role")
    var role: UserRole

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        fullName: String,
        email: String,
        passwordHash: String,
        role: UserRole = .customer
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
    }
}

// JWT Payload for User
struct UserPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case role
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var role: UserRole

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        password == passwordHash
    }
}
