import Vapor
import Fluent
import JWT

enum UserRole: String, Codable {
    case admin
    case customer
}

enum AuthProvider: String, Codable {
    case email
    case google
}

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "full_name")
    var fullName: String

    @Field(key: "email")
    var email: String

    @OptionalField(key: "password_hash")
    var passwordHash: String?

    @Field(key: "role")
    var role: UserRole

    @Field(key: "auth_provider")
    var authProvider: AuthProvider

    @OptionalField(key: "google_id")
    var googleId: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        fullName: String,
        email: String,
        passwordHash: String? = nil,
        role: UserRole = .customer,
        authProvider: AuthProvider = .email,
        googleId: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.authProvider = authProvider
        self.googleId = googleId
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
