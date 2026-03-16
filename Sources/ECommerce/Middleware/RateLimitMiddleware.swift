import Vapor
import Foundation

actor RateLimitStore {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let windowSeconds: TimeInterval

    init(maxRequests: Int, windowSeconds: TimeInterval) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    func shouldAllow(key: String) -> Bool {
        let now = Date()
        let windowStart = now.addingTimeInterval(-windowSeconds)

        var timestamps = requests[key, default: []]
        timestamps = timestamps.filter { $0 > windowStart }

        if timestamps.count >= maxRequests {
            requests[key] = timestamps
            return false
        }

        timestamps.append(now)
        requests[key] = timestamps
        return true
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    let store: RateLimitStore

    init(maxRequests: Int = 10, windowSeconds: TimeInterval = 60) {
        self.store = RateLimitStore(maxRequests: maxRequests, windowSeconds: windowSeconds)
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let key = request.peerAddress?.description ?? request.remoteAddress?.description ?? "unknown"

        guard await store.shouldAllow(key: key) else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
