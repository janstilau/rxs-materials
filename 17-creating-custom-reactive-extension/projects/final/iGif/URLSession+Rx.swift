import Foundation
import RxSwift

private var internalCache = [String: Data]()

public enum RxURLSessionError: Error {
    case unknown
    case invalidResponse(response: URLResponse)
    case requestFailed(response: HTTPURLResponse, data: Data?)
    case deserializationFailed
}

extension Reactive where Base: URLSession {
    
    // 使用 Observable, 很少使用 Bool 来进行结果的判断. 因为 Event 天然就是有着 Bool 值的逻辑.
    func response(request: URLRequest) -> Observable<(HTTPURLResponse, Data)> {
        
        /*
         Observable.create 和 Promise 的构建是一样的.
         创建一个对象, 存储了各种回调, 然后通过改变自身的状态, 来触发这些回调.
         所以, 闭包里面的参数, 就是能够改变这个对象状态的一个工具对象.
         */
        return Observable.create { observer in
            // content goes here
            let task = self.base.dataTask(with: request) { data, response, error in
                guard let response = response,
                      let data = data else {
                          observer.onError(error ?? RxURLSessionError.unknown)
                          return
                      }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(RxURLSessionError.invalidResponse(response: response))
                    return
                }
                
                observer.onNext((httpResponse, data))
                observer.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create { task.cancel() }
        }
    }
    
    func data(request: URLRequest) -> Observable<Data> {
        // 这里有缓存的使用.
        if let url = request.url?.absoluteString,
           let data = internalCache[url] {
            // Just 很像是变量, 可以直接进行使用.
            // 这里直接返回了, 那么整个响应链条, 就不会走向 response, cache, map 了. 直接在这里就中断了
            //  Observable.just(data) 是整个响应链条的头结点. 
            return Observable.just(data)
        }
        
        // 这里的 map 的作用, 是丢弃 response 这个值.
        return response(request: request).cache().map { response, data -> Data in
            guard 200 ..< 300 ~= response.statusCode else {
                throw RxURLSessionError.requestFailed(response: response, data: data)
            }
            
            return data
        }
    }
    
    // 一层层的, 使用已经创建出来的 Observable, 进行加工 .
    func string(request: URLRequest) -> Observable<String> {
        return data(request: request).map { data in
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
    
    func json(request: URLRequest) -> Observable<Any> {
        return data(request: request).map { data in
            return try JSONSerialization.jsonObject(with: data)
        }
    }
    
    func decodable<D: Decodable>(request: URLRequest, type: D.Type) -> Observable<D> {
        return data(request: request).map { data in
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        }
    }
    
    func image(request: URLRequest) -> Observable<UIImage> {
        return data(request: request).map { data in
            return UIImage(data: data) ?? UIImage()
        }
    }
}

extension ObservableType where Element == (HTTPURLResponse, Data) {
    
    func cache() -> Observable<Element> {
        // do, 是一个完全不会影响到数据传递的一个 Operator.
        // 所以, 它是一个进行副作用的良好的场所. 
        return self.do(onNext: { response, data in
            guard let url = response.url?.absoluteString,
                  200 ..< 300 ~= response.statusCode else { return }
            internalCache[url] = data
        })
    }
}
