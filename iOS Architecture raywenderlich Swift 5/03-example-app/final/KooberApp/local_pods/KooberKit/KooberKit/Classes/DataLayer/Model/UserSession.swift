import Foundation

public class UserSession: Codable {
    
    // MARK: - Properties
    public let profile: UserProfile // 本地的数据部分.
    public let remoteSession: RemoteUserSession // 网络请求的数据部分.
    
    // MARK: - Methods
    public init(profile: UserProfile, remoteSession: RemoteUserSession) {
        self.profile = profile
        self.remoteSession = remoteSession
    }
}

extension UserSession: Equatable {
    
    // lhs, rhs 是一个非常通用的命名方式.
    public static func ==(lhs: UserSession, rhs: UserSession) -> Bool {
        return lhs.profile == rhs.profile &&
        lhs.remoteSession == rhs.remoteSession
    }
}
