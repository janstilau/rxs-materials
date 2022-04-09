import Foundation

public typealias RideOptionID = String

public struct RideOption: Equatable, Identifiable, Decodable {
    
    // MARK: - Properties
    public var id: RideOptionID
    public var name: String
    // 当, 结构固定的时候, 使用元组. 节省类型的定义.
    public var buttonRemoteImages: (selected: RemoteImage, unselected: RemoteImage)
    public var availableMapMarkerRemoteImage: RemoteImage
    
    // MARK: - Methods
    public init(id: RideOptionID,
                name: String,
                buttonRemoteImages: (RemoteImage, RemoteImage),
                availableMapMarkerRemoteImage: RemoteImage) {
        self.id = id
        self.name = name
        self.buttonRemoteImages = buttonRemoteImages
        self.availableMapMarkerRemoteImage = availableMapMarkerRemoteImage
    }
    
    // 具有 ID 值的判等, 是通过 ID 作为代表就可以了.
    public static func ==(lhs: RideOption, rhs: RideOption) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case segmentSelectedImageLocation
        case segmentImageLocation
        case availableMapMarkerImageLocation
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id =
        try values.decode(RideOptionID.self, forKey: .id)
        name =
        try values.decode(String.self, forKey: .name)
        
        let selectedImage =
        try values.decode(RemoteImage.self, forKey: .segmentSelectedImageLocation)
        let unselectedImage =
        try values.decode(RemoteImage.self, forKey: .segmentImageLocation)
        buttonRemoteImages = (selectedImage, unselectedImage)
        
        availableMapMarkerRemoteImage =
        try values.decode(RemoteImage.self, forKey: .availableMapMarkerImageLocation)
    }
}


