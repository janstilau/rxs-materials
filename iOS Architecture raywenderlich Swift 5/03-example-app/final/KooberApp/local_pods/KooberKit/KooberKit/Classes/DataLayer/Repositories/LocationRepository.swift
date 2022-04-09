import Foundation
import PromiseKit

// 定义一个抽象类型, 然后实现这个抽象类型.
//
public protocol LocationRepository {
    
    func searchForLocations(using query: String, pickupLocation: Location) -> Promise<[NamedLocation]>
}
