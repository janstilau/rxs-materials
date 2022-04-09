import Foundation

// 不在原有的 Location 了上, 增加属性, 而是用一个新的类进行包装. 
public struct NamedLocation: Equatable, Codable {
    
    // MARK: - Properties
    public internal(set) var name: String
    public internal(set) var location: Location
    
    // MARK: - Methods
    public init(name: String, location: Location) {
        self.name = name
        self.location = location
    }
}
