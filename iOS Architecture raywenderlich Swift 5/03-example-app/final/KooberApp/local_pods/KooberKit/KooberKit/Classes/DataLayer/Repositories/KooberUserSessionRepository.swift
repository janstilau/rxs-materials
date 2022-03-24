import Foundation
import PromiseKit

/*
 UserSessionRepository
 func readUserSession() -> Promise<UserSession?>
 func signUp(newAccount: NewAccount) -> Promise<UserSession>
 func signIn(email: String, password: String) -> Promise<UserSession>
 func signOut(userSession: UserSession) -> Promise<UserSession>
 
 实现了上面的协议.
 具体如何实现的, 是通过本地读取, 以及网络请求两种方式.
 将这两部分, 又通过接口进行了抽象.
 由外部传入应该应该依赖的具体对象, 在内部仅仅使用, 抽象出来的接口.
 */
public class KooberUserSessionRepository: UserSessionRepository {
    
    // MARK: - Properties
    let dataStore: UserSessionDataStore
    let remoteAPI: AuthRemoteAPI
    
    // MARK: - Methods
    public init(dataStore: UserSessionDataStore, remoteAPI: AuthRemoteAPI) {
        self.dataStore = dataStore
        self.remoteAPI = remoteAPI
    }
    
    // 本地读取, 理所应该是本地服务接口,
    public func readUserSession() -> Promise<UserSession?> {
        return dataStore.readUserSession()
    }
    
    // 使用 api 进行网络请求, 在后面桥接了 dataStore 的缓存操作.
    // 因为 DataStore 也是一个 Promise, 所以可以桥接.
    // 这里有个问题, 本来这是一个并发的行为, 现在这样, 就变为串行的了.
    public func signUp(newAccount: NewAccount) -> Promise<UserSession> {
        return remoteAPI.signUp(account: newAccount)
        // Then 里面, 放入的是一个闭包对象. 没有直接调用.
        // 看来, 出参入参一直, 直接将闭包传入的方式, 在 Promise 里面非常常见.
            .then(dataStore.save(userSession:))
    }
    
    public func signIn(email: String, password: String) -> Promise<UserSession> {
        return remoteAPI.signIn(username: email, password: password)
            .then(dataStore.save(userSession:))
    }
    
    public func signOut(userSession: UserSession) -> Promise<UserSession> {
        return dataStore.delete(userSession: userSession)
    }
}
