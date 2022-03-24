import Foundation
import PromiseKit

public class FileUserSessionDataStore: UserSessionDataStore {
    
    // MARK: - Properties
    var docsURL: URL? {
        return FileManager
            .default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                          in: FileManager.SearchPathDomainMask.allDomainsMask).first
    }
    
    // MARK: - Methods
    public init() {}
    
    // 读
    public func readUserSession() -> Promise<UserSession?> {
        // 这是 Promise 的最常用的生成方式, 和 Observable.Create 是同样的一个思路.
        // 在内部, 生成一个 Resolver, 然后将 Promise 的状态传递给他, 调用 Resolver 的方法, 就是在改变 Pormise 的状态.
        // 这个过程封装起来, Promise 生成的时候, 传入的闭包就是, 调用异步函数, 同步也可以, 然后在合适的实际, 进行 Resolver 的触发.
        // 因为 Promise 里面, 可以存储原来的状态, 所以 Resolver 是可以在 Body 里面直接确定状态的.
        // 后续的注册, 可以直接从已经 Seal 的缓存状态中, 获取值.
        return Promise() { seal in
            guard let docsURL = docsURL else {
                seal.reject(KooberKitError.any)
                return
            }
            guard let jsonData = try? Data(contentsOf: docsURL.appendingPathComponent("user_session.json")) else {
                // 如果, 读取不导致, 那么就是没有本地的用户信息,
                // 这个时候还是 fulfill 的状态, 只不过没有数据而已.
                seal.fulfill(nil)
                return
            }
            // 进行数据的解析, 然后确定 Promise 的状态.
            let decoder = JSONDecoder()
            let userSession = try! decoder.decode(UserSession.self, from: jsonData)
            seal.fulfill(userSession)
        }
    }
        
    // 从这里的实现来看, 和同步的方法, 返回 true, false, 没有任何的区别.
    // 不过要记住, Promise 在执行的时候, 其实是主动进行了 async 的调度的, 所以, 必然是一个异步操作.
    public func save(userSession: UserSession) -> Promise<(UserSession)> {
        return Promise() { seal in
            let encoder = JSONEncoder()
            let jsonData = try! encoder.encode(userSession)
            
            guard let docsURL = docsURL else {
                seal.reject(KooberKitError.any)
                return
            }
            try? jsonData.write(to: docsURL.appendingPathComponent("user_session.json"))
            seal.fulfill(userSession)
        }
    }
    
    public func delete(userSession: UserSession) -> Promise<(UserSession)> {
        return Promise() { seal in
            guard let docsURL = docsURL else {
                seal.reject(KooberKitError.any)
                return
            }
            // 直接就是文件的删除.
            // 这里可以写成, gurantee.
            do {
                try FileManager.default.removeItem(at: docsURL.appendingPathComponent("user_session.json"))
            } catch {
                seal.reject(KooberKitError.any)
                return
            }
            seal.fulfill(userSession)
        }
    }
}
