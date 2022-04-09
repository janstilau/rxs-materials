
import Foundation
import PromiseKit

// Fake 就是为了方便开发的, 所有, 它可以暴露出各种属性出来, 这些属性, 就是为了能够方便的按照 dev 的需求, 来影响内部实现的.
// 这是没有问题的, 使用 Fake 的时候, 就应该默认, 是完全了解其中的内部实现, 来使用这个类的.
// 当然, 实现类, 必须完成, 接口里面实现的所有接口.
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
    
    // Delete, 直接返回原始值, 代表着删除成功了.
    public func delete(userSession: UserSession) -> Promise<(UserSession)> {
        return .value(userSession)
    }
    
    // 根据, 成员变量的配置结果, 来返回不同的实现.
    public func readUserSession() -> Promise<UserSession?> {
        switch hasToken {
        case true:
            return runHasToken()
        case false:
            return runDoesNotHaveToken()
        }
    }
    
    // 返回用户数据.
    public func runHasToken() -> Promise<UserSession?> {
        print("Try to read user session from fake disk...")
        print("  simulating having user session with token 4321...")
        print("  returning user session with token 4321...")
        let profile = UserProfile(name: "", email: "", mobileNumber: "", avatar: makeURL())
        let remoteSession = RemoteUserSession(token: "1234")
        return .value(UserSession(profile: profile, remoteSession: remoteSession))
    }
    
    // 不返回用户数据. 
    func runDoesNotHaveToken() -> Promise<UserSession?> {
        print("Try to read user session from fake disk...")
        print("  simulating empty disk...")
        print("  returning nil...")
        return .value(nil)
    }
}
