import Foundation
import PromiseKit

public protocol NewRideRemoteAPI {
    
    func getRideOptions(pickupLocation: Location) -> Promise<[RideOption]>
    func getLocationSearchResults(query: String, pickupLocation: Location) -> Promise<[NamedLocation]>
    // Update 网络请求, 需要的结果, 也就是成功失败与否而已.
    func post(newRideRequest: NewRideRequest) -> Promise<Void>
}

enum RemoteAPIError: Error {
    
    case unknown
    case createURL
    case httpError
}
