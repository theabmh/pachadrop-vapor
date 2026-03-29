import Fluent
import SQLKit

struct AddGoogleAuthToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            fatalError("AddGoogleAuthToUser migration requires a SQL database")
        }
        // Make password_hash nullable (email/password users keep their hash; Google-only users have nil)
        try await sql.raw("ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL").run()
        // google_id: unique identifier from Google's 'sub' claim
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR UNIQUE").run()
        // auth_provider: tracks how the account was originally created
        try await sql.raw("ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR NOT NULL DEFAULT 'email'").run()
    }

    func revert(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            fatalError("AddGoogleAuthToUser revert requires a SQL database")
        }
        try await sql.raw("ALTER TABLE users DROP COLUMN IF EXISTS google_id").run()
        try await sql.raw("ALTER TABLE users DROP COLUMN IF EXISTS auth_provider").run()
        try await sql.raw("ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL").run()
    }
}
