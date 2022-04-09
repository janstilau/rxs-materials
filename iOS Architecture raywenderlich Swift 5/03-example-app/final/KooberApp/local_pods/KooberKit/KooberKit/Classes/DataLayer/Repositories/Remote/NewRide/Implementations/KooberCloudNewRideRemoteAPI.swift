import Foundation
import PromiseKit

// 真实的网络请求实现类.
// 实现了 NewRideRemoteAPI 的抽象.
public class KooberCloudNewRideRemoteAPI: NewRideRemoteAPI {
    
    // MARK: - Properties
    let userSession: RemoteUserSession
    let urlSession: URLSession
    let domain = "localhost"
    
    // MARK: - Methods
    // 每次, 都进行相关需要的数据的传入, 其实是一个很厌烦的事情.
    // 这个时候, 可能最方便的地方, 就是使用单例了.
    // YD 是使用了 SERVICE 这样的一个概念. 其实, 还是使用单例, 只不过这个单例, 是一个生成器的概念.
    // 使用单例, 获取到抽象接口对象.
    public init(userSession: RemoteUserSession) {
        self.userSession = userSession
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(userSession.token)"]
        self.urlSession = URLSession(configuration: config)
    }
    
    // 简单的 URLSession 的封装, 然后在内部, 进行了 Promise 的状态改变.
    // Promise, Rx 的构建异步任务, 其实都是一个套路.
    // 在异步任务的相关位置, 进行节点的状态改变.
    public func getRideOptions(pickupLocation: Location) -> Promise<[RideOption]> {
        // public init(resolver body: (Resolver<T>) throws -> Void)  的使用.
        return Promise<[RideOption]> { seal in
            // Build URL
            let urlString = "http://\(domain):8080/rideOptions?latitude=\(pickupLocation.latitude)&longitude=\(pickupLocation.longitude)"
            guard let url = URL(string: urlString) else {
                seal.reject(RemoteAPIError.createURL)
                return
            }
            
            // Send Data Task
            urlSession.dataTask(with: url) { data, response, error in
                // 这里可以看到, 不用强制的使用 Guard. 自己在写代码的时候, 也是感觉到了.
                // 在不合适的地方, 使用 Guard, 会让代码怪怪的.
                if let error = error {
                    seal.reject(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    seal.reject(RemoteAPIError.unknown)
                    return
                }
                guard 200..<300 ~= httpResponse.statusCode else {
                    seal.reject(RemoteAPIError.httpError)
                    return
                }
                guard let data = data else {
                    seal.reject(RemoteAPIError.unknown)
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let rideOptions = try decoder.decode([RideOption].self, from: data)
                    seal.fulfill(rideOptions)
                } catch let error as NSError {
                    seal.reject(error)
                }
            }.resume()
        }
    }
    
    public func getLocationSearchResults(query: String, pickupLocation: Location) -> Promise<[NamedLocation]> {
        return Promise<[NamedLocation]> { seal in
            // Build URL
            let urlString = "http://\(domain):8080/locations?query=\(query)&latitude=\(pickupLocation.latitude)&longitude=\(pickupLocation.longitude)"
            guard let url = URL(string: urlString) else {
                seal.reject(RemoteAPIError.createURL)
                return
            }
            // Send Data Task
            urlSession.dataTask(with: url) { data, response, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    seal.reject(RemoteAPIError.unknown)
                    return
                }
                guard 200..<300 ~= httpResponse.statusCode else {
                    seal.reject(RemoteAPIError.httpError)
                    return
                }
                guard let data = data else {
                    seal.reject(RemoteAPIError.unknown)
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let searchResults = try decoder.decode([NamedLocation].self, from: data)
                    seal.fulfill(searchResults)
                } catch let error as NSError {
                    seal.reject(error)
                }
            }.resume()
        }
    }
    
    // 如果, Promise 里面, T 是 (), 就是代表着这就是一个事件触发.
    // T 中不会有 Success 这种 Bool 值, 以为如果有问题, 直接是 Reject 的状态了就.
    public func post(newRideRequest: NewRideRequest) -> Promise<()> {
        return Promise<Void> { seal in
            // Build URL
            guard let url = URL(string: "http://\(domain):8080/ride") else {
                seal.reject(RemoteAPIError.createURL)
                return
            }
            // Build Request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // Encode JSON
            do {
                let data = try JSONEncoder().encode(newRideRequest)
                request.httpBody = data
            } catch {
                seal.reject(error)
                return
            }
            // Send Data Task
            urlSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    seal.reject(RemoteAPIError.unknown)
                    return
                }
                guard 200..<300 ~= httpResponse.statusCode else {
                    seal.reject(RemoteAPIError.httpError)
                    return
                }
                seal.fulfill(())
            }.resume()
        }
    }
}

extension RemoteAPIError: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .unknown:
            return "Koober had a problem loading some data.\nPlease try again soon!"
        case .createURL:
            return "Koober had a problem creating a URL.\nPlease try again soon!"
        case .httpError:
            return "Koober had a problem loading some data.\nPlease try again soon!"
        }
    }
}
