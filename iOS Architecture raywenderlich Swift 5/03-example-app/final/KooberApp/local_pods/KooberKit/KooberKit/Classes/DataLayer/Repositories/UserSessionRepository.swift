import Foundation
import PromiseKit

/*
 和自己的习惯一样, 类型下面的空行是必须的.
 用户数据相关的操作. 相比较同步获取的方式, 全部都是异步回调的方式.
 如果, 不使用 Promise 的方式, 那么这个接口就全部都是闭包传递的方式了.
 */
public protocol UserSessionRepository {
    
    func readUserSession() -> Promise<UserSession?>
    func signUp(newAccount: NewAccount) -> Promise<UserSession>
    func signIn(email: String, password: String) -> Promise<UserSession>
    func signOut(userSession: UserSession) -> Promise<UserSession>
}
