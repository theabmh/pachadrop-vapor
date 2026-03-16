import Vapor
import Foundation

struct RequestLoggingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let requestId = request.headers.first(name: "X-Request-ID") ?? UUID().uuidString
        let start = Date()

        request.logger[metadataKey: "request-id"] = .string(requestId)
        request.logger.info("Incoming \(request.method) \(request.url.path)")

        let response: Response
        do {
            response = try await next.respond(to: request)
        } catch {
            let duration = Date().timeIntervalSince(start)
            request.logger.error("Request failed after \(String(format: "%.3f", duration))s: \(error)")
            throw error
        }

        let duration = Date().timeIntervalSince(start)
        request.logger.info("Completed \(response.status.code) in \(String(format: "%.3f", duration))s")

        response.headers.add(name: "X-Request-ID", value: requestId)
        return response
    }
}
