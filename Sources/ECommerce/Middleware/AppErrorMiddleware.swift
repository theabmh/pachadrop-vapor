import Vapor

struct AppErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let abort as Abort {
            let body = BaseResponseModel<EmptyData>.error(
                message: abort.reason,
                error: String(describing: abort.status),
                statusCode: Int(abort.status.code),
                reason: abort.reason
            )
            let response = Response(status: abort.status)
            try response.content.encode(body)
            return response
        } catch {
            let body = BaseResponseModel<EmptyData>.error(
                message: "Internal Server Error",
                error: "internalServerError",
                statusCode: 500,
                reason: error.localizedDescription
            )
            let response = Response(status: .internalServerError)
            try response.content.encode(body)
            return response
        }
    }
}
