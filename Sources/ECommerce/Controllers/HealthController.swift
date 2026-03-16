import Vapor
import Fluent

struct HealthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: health)
    }

    func health(req: Request) async throws -> BaseResponseModel<HealthResponse> {
        var dbStatus = "healthy"
        do {
            _ = try await req.db.query(User.self).count()
        } catch {
            dbStatus = "unhealthy: \(error.localizedDescription)"
        }

        let response = HealthResponse(
            status: dbStatus == "healthy" ? "healthy" : "degraded",
            database: dbStatus,
            timestamp: Date()
        )

        return .success(response, message: "Service is running")
    }
}

struct HealthResponse: Content {
    let status: String
    let database: String
    let timestamp: Date
}
