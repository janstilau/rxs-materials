import Foundation
import PromiseKit

public typealias AuthToken = String

/*
 接口, 代表的是能力.
 这个接口代表的是, 有本地操作用户数据的能力.
 
 针对 UserSessionDataStore 这层抽象, 作者一共给了三个实现类.
 在初始化的时候, 根据配置, 生成不同的实现方法, 使用到 UserSessionDataStore 的地方, 仅仅根据接口进行使用, 并不知道里面的实现细节.
 */
public protocol UserSessionDataStore {
    
    func readUserSession() -> Promise<UserSession?> // 读
    func save(userSession: UserSession) -> Promise<(UserSession)> // 存
    func delete(userSession: UserSession) -> Promise<(UserSession)> // 写
}
