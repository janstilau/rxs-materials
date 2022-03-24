import Foundation

/*
 虽然, 仅仅是一个 Token 字符串成员变量, 但是还是使用了一个专门的类进行了存储.
 */
public struct RemoteUserSession: Codable {
    
    // MARK: - Properties
    let token: AuthToken
    
    // MARK: - Methods
    public init(token: AuthToken) {
        self.token = token
    }
}

extension RemoteUserSession: Equatable {
    
    public static func ==(lhs: RemoteUserSession, rhs: RemoteUserSession) -> Bool {
        return lhs.token == rhs.token
    }
}
