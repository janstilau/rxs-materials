import Foundation
import PromiseKit

// 对于 LocationRepository 的实现.
// 可以看到, 并没有对于 LocationRepository 使用 Protocol 来命名. 而是在实现的时候, 使用了业务相关的前缀.
// 对于 Fake 来说, 也就是 FakeLocationRepository 就可以了.
public class KooberLocationRepository: LocationRepository {
    
    // MARK: - Properties
    let remoteAPI: NewRideRemoteAPI
    
    // MARK: - Methods
    public init(remoteAPI: NewRideRemoteAPI) {
        self.remoteAPI = remoteAPI
    }
    
    public func searchForLocations(using query: String, pickupLocation: Location) -> Promise<[NamedLocation]> {
        return remoteAPI.getLocationSearchResults(query: query, pickupLocation: pickupLocation)
    }
}
