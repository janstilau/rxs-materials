import Foundation
import PromiseKit

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
