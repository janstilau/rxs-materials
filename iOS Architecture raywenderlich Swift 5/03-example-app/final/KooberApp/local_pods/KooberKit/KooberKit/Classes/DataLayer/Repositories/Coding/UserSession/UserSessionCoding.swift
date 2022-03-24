import Foundation

// 专门, 为 User 的解析, 定义出来了一个协议.
public protocol UserSessionCoding {
  
  func encode(userSession: UserSession) -> Data
  func decode(data: Data) -> UserSession
}
