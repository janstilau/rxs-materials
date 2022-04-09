import Foundation

public typealias LocationID = String

// 在库内, 可以进行 set 操作, 但是在库外, 只能进行读取.
public struct Location: Identifiable, Equatable, Codable {
    
    // MARK: - Properties
    public internal(set) var id: LocationID
    public internal(set) var latitude: Double
    public internal(set) var longitude: Double
    
    // MARK: - Methods
    public init(id: LocationID, latitude: Double, longitude: Double) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
    }
}
