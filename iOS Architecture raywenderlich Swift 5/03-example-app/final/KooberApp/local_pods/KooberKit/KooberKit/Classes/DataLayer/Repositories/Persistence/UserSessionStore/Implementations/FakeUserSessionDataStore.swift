
import Foundation
import PromiseKit

// 因为, UserSessionDataStore 是一个接口, 使用到的地方, 也是用接口的方式使用的.
// 所以, 方便了测试, 可以专门写一个接口类, 专门进行测试. 只要他实现了接口要求的值就可以了.

// Promise 这种方式, 使得原本的闭包传递, 变为了同步的回调注册的机制.
public class FakeUserSessionDataStore: UserSessionDataStore {
    
    // MARK: - Properties
    let hasToken: Bool
    
    // MARK: - Methods
    init(hasToken: Bool) {
        self.hasToken = hasToken
    }
    
    // Save, 就直接返回原始值, 代表存储成功了.
    public func save(userSession: UserSession) -> Promise<(UserSession)> {
        return .value(userSession)
    }
    
    public func delete(userSession: UserSession) -> Promise<(UserSession)> {
        return .value(userSession)
    }
    
    // 这是一个 Fake 类, 所以其实除了实现的接口, 还是可以有自己的成员变量的
    // 这些成员变量, 就是为了影响这些接口的实现.
    // 在生成的时候, 配置这些, 可以达到, 使用测试数据, 影响接口的效果. 
    public func readUserSession() -> Promise<UserSession?> {
        switch hasToken {
        case true:
            return runHasToken()
        case false:
            return runDoesNotHaveToken()
        }
    }
    
    public func runHasToken() -> Promise<UserSession?> {
        print("Try to read user session from fake disk...")
        print("  simulating having user session with token 4321...")
        print("  returning user session with token 4321...")
        let profile = UserProfile(name: "", email: "", mobileNumber: "", avatar: makeURL())
        let remoteSession = RemoteUserSession(token: "1234")
        return .value(UserSession(profile: profile, remoteSession: remoteSession))
    }
    
    func runDoesNotHaveToken() -> Promise<UserSession?> {
        print("Try to read user session from fake disk...")
        print("  simulating empty disk...")
        print("  returning nil...")
        return .value(nil)
    }
}
