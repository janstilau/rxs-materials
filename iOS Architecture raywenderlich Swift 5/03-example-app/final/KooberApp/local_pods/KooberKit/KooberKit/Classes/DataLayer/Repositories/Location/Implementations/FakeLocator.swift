import Foundation
import PromiseKit

// 项目里面, 没有给出真实的 Locator 出来.
// 真实的, 一定是调用系统的 API .
public class FakeLocator: Locator {
    
    // MARK: - Methods
    public init() {}
    
    public func getUsersCurrentLocation() -> Promise<Location> {
        return Promise { seal in
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
                let location = Location(id: "0", latitude: -33.864308, longitude: 151.209146)
                seal.fulfill(location)
            }
        }
    }
}
