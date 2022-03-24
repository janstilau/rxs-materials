import Foundation

/*
 一个纯数据类, 可以参考一下代码的组织方式.
 和自己的代码组织方式很像. 一个类型下面, 空行用来进行分割.
 */
public struct UserProfile: Equatable, Codable {
    
    // MARK: - Properties
    public let name: String
    public let email: String
    public let mobileNumber: String
    public let avatar: URL
    
    // MARK: - Methods
    public init(name: String, email: String, mobileNumber: String, avatar: URL) {
        self.name = name
        self.email = email
        self.mobileNumber = mobileNumber
        self.avatar = avatar
    }
}
