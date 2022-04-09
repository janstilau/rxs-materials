import Foundation
import PromiseKit

// 使用, 文件的方式, 来进行用户数据的存储.
public class FileUserSessionDataStore: UserSessionDataStore {
    
    // MARK: - Properties
    var docsURL: URL? {
        return FileManager
            .default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                             in: FileManager.SearchPathDomainMask.allDomainsMask).first
    }
    
    // MARK: - Methods
    public init() {}
    
    // 读, 从文件里面进行读取.
    public func readUserSession() -> Promise<UserSession?> {
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
    // 写, 写到文件中, 如果成功, 把原始的数据进行 fulfill.
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
    
    // 删除, 将文件删除后, 进行 resolve
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
