import Foundation
import PromiseKit

// 通过, 将网络请求接口, 抽象成为业务参数和返回数据, 使得网络请求这件事, 也变为了协议.
// 
public protocol AuthRemoteAPI {
    
    func signIn(username: String, password: String) -> Promise<UserSession>
    func signUp(account: NewAccount) -> Promise<UserSession>
}
