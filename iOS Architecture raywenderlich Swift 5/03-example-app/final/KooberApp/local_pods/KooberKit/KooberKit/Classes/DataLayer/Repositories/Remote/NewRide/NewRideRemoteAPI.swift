import Foundation
import PromiseKit

// 各个, 使用到骑行相关的业务 API, 封装到一个地方.
// Model 的定义, 是和网络请求无关的, 网络数据如何返回, 和自己 App 内使用什么样的数据, 应该分开.
// 现在有道里面, 将 API 和 Model 定义写到一起的策略, 其实是有点问题的.
// 所有, 使用到 Ride 相关 API 的地方, 都是使用 NewRideRemoteAPI 这个抽象类型, 没有使用到实际类.
public protocol NewRideRemoteAPI {
    
    func getRideOptions(pickupLocation: Location) -> Promise<[RideOption]>
    func getLocationSearchResults(query: String, pickupLocation: Location) -> Promise<[NamedLocation]>
    // Update 网络请求, 需要的结果, 也就是成功失败与否而已.
    func post(newRideRequest: NewRideRequest) -> Promise<Void>
}

// 这个抽象, 对应的错误, 在这个抽象的定义文件中进行指定. 
enum RemoteAPIError: Error {
    
    case unknown
    case createURL
    case httpError
}
