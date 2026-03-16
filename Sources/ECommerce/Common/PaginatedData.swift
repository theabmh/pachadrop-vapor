import Vapor

struct PaginatedData<T: Content>: Content {
    let items: [T]
    let total: Int
    let page: Int
    let perPage: Int
    let totalPages: Int
}
