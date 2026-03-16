import Vapor

struct BaseResponseModel<T: Content>: Content {
    var message: String
    var data: T?
    var error: String?
    var status: String
    var statusCode: Int
    var reason: String?
}

extension BaseResponseModel {
    static func success(_ data: T, message: String = "Success", statusCode: Int = 200) -> BaseResponseModel {
        BaseResponseModel(
            message: message,
            data: data,
            error: nil,
            status: "success",
            statusCode: statusCode,
            reason: nil
        )
    }

    static func created(_ data: T, message: String = "Created successfully") -> BaseResponseModel {
        BaseResponseModel(
            message: message,
            data: data,
            error: nil,
            status: "success",
            statusCode: 201,
            reason: nil
        )
    }
}

extension BaseResponseModel where T == EmptyData {
    static func noContent(message: String = "Deleted successfully") -> BaseResponseModel<EmptyData> {
        BaseResponseModel<EmptyData>(
            message: message,
            data: nil,
            error: nil,
            status: "success",
            statusCode: 200,
            reason: nil
        )
    }

    static func error(
        message: String,
        error: String,
        statusCode: Int,
        reason: String? = nil
    ) -> BaseResponseModel<EmptyData> {
        BaseResponseModel<EmptyData>(
            message: message,
            data: nil,
            error: error,
            status: "error",
            statusCode: statusCode,
            reason: reason
        )
    }
}
