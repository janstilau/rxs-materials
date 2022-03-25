import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import MapKit

class ApiController {
    
    struct Weather: Decodable {
        
        let cityName: String
        let temperature: Int
        let humidity: Int
        let icon: String
        let coordinate: CLLocationCoordinate2D
        
        // 提前定义的静态值, 在 error 发生, 或者起始状态可以直接使用.
        static let empty = Weather(
            cityName: "Unknown",
            temperature: -1000,
            humidity: 0,
            icon: iconNameToChar(icon: "e"),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        static let dummy = Weather(
            cityName: "RxCity",
            temperature: 20,
            humidity: 90,
            icon: iconNameToChar(icon: "01d"),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        init(cityName: String,
             temperature: Int,
             humidity: Int,
             icon: String,
             coordinate: CLLocationCoordinate2D) {
            self.cityName = cityName
            self.temperature = temperature
            self.humidity = humidity
            self.icon = icon
            self.coordinate = coordinate
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            cityName = try values.decode(String.self, forKey: .cityName)
            let info = try values.decode([AdditionalInfo].self, forKey: .weather)
            icon = iconNameToChar(icon: info.first?.icon ?? "")
            
            // 这里体现了, nestedContainer 的用法.
            // 那就是不想重新定义一个数据结构, 来配合 JSON 中的结构.
            // 可以手动的进入到下一个层级, 然后将下一个层级中的数据, 解析到当前等级来.
            // 第一次见到这样的方式.
            let mainInfo = try values.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
            temperature = Int(try mainInfo.decode(Double.self, forKey: .temp))
            humidity = try mainInfo.decode(Int.self, forKey: .humidity)
            
            let coordinate = try values.decode(Coordinate.self, forKey: .coordinate)
            self.coordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }
        
        enum CodingKeys: String, CodingKey {
            case cityName = "name"
            case main
            case weather
            case coordinate = "coord"
        }
        
        enum MainKeys: String, CodingKey {
            case temp
            case humidity
        }
        
        private struct AdditionalInfo: Decodable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }
        
        private struct Coordinate: Decodable {
            let lat: CLLocationDegrees
            let lon: CLLocationDegrees
        }
    }
    
    enum ApiError: Error {
        case cityNotFound
        case serverFailure
        case invalidKey
    }
    
    /// The shared instance
    static var shared = ApiController()
    
    
    // 从这里可以看到, 其实可以将 BehaviorSubject 这种类型的 Subject, 当做成员变量来用的.
    // 不可能, 所有的都是响应式. 所以, 一定要有指令式的代码.
    let apiKey = BehaviorSubject(value: "197d815bb621986c704668dde0b27e5d")
    
    /// API base URL
    let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!
    
    init() {
        Logging.URLRequests = { request in
            return true
        }
    }
    
    // MARK: - Api Calls
    func currentWeather(city: String) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("q", city)])
        // buildRequest, 已经将 Session 的 Observable<(response: HTTPURLResponse, data: Data)>
        // 变化成为了 Observable<Data>
        // 所以添加节点的时候, 直接从 Data 入手其实就可以了.
            .map { data in
                let decoder = JSONDecoder()
                return try decoder.decode(Weather.self, from: data)
            }
    }
    
    func currentWeather(at coordinate: CLLocationCoordinate2D) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("lat", "\(coordinate.latitude)"),
                                                               ("lon", "\(coordinate.longitude)")])
            .map { data in
                let decoder = JSONDecoder()
                return try decoder.decode(Weather.self, from: data)
            }
    }
    
    // MARK: - Private Methods
    
    /*
     * Private method to build a request with RxCocoa
     */
    // 同原有的代码组织结构一样, 还是可以编写, 返回通用的数据结构的方法.
    // 然后, 在这个方法的基础上, 进行后续逻辑的处理. 因为, rx 是一种线性的结构, 他包装的应该是返回一种通用的数据结构, 然后交给后面进行变化.
    private func buildRequest(method: String = "GET",
                              pathComponent: String,
                              params: [(String, String)]) -> Observable<Data> {
        
        // 这里其实就是一个构建 Request 的过程.
        // 但是我们想的是, 把这个过程, 变为事件序列的一部分.
        let request: Observable<URLRequest> = Observable.create { observer in
            let url = self.baseURL.appendingPathComponent(pathComponent)
            var request = URLRequest(url: url)
            
            let keyQueryItem = URLQueryItem(name: "appid", value: try? self.apiKey.value())
            let unitsQueryItem = URLQueryItem(name: "units", value: "metric")
            let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
            
            if method == "GET" {
                var queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
                queryItems.append(keyQueryItem)
                queryItems.append(unitsQueryItem)
                urlComponents.queryItems = queryItems
            } else {
                urlComponents.queryItems = [keyQueryItem, unitsQueryItem]
                let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                request.httpBody = jsonData
            }
            
            request.url = urlComponents.url!
            request.httpMethod = method
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 其实, 将 Request 的构建构成, 暴露在外面, 然后 Observable.create 使用这个捕获的 Request 也是没有问题的.
            // 但现在的这种代码方式, 更加的合理和清晰, 将事件的源头仅仅的包裹.
            // 后续的代码, 直接拿到的就是响应式的代码结构.
            observer.onNext(request)
            observer.onCompleted()
            
            return Disposables.create()
        }
        
        let session = URLSession.shared
        
        // 调用 FlatMap --> 当上游的数据节点达到之后, 触发 FlatMap 里面的事件序列的逻辑.
        // 然后后续的节点, 其实是监听的这个生成的事件序列的值.
        // flatMap 很像是, Promise 的 then.
        
        /*
         FlatMap 的处理逻辑, 是将生成的事件序列, 调用 subscribe 注册到一个中间节点, 中间节点将生成的事件序列的值, 传递给 flatMap 的后续节点.
         所以 flatMap 中的事件序列, 只有到上游节点来临时, 才会真正的产生数据源.
         */
        return request.flatMap { request in
            
            // Observable<(response: HTTPURLResponse, data: Data)>
            // session.rx.response --> Observable<(response: HTTPURLResponse, data: Data)>
            // rx 官方包装的 resposne 是这样的一个序列.
            return session.rx.response(request: request)
                .map { response, data in
                    // 在这里的处理是, 根据 code 的值, 进行了 throw 的处理
                    // 而之所以可以进行 throw, 是因为 map 里面, 接受到的是一个 throw 的 Block
                    switch response.statusCode {
                    case 200 ..< 300:
                        return data
                    case 401:
                        throw ApiError.invalidKey
                    case 400 ..< 500:
                        // 在熟知了服务器端逻辑的情况下, 才能写出这样的代码出来. 
                        throw ApiError.cityNotFound
                    default:
                        throw ApiError.serverFailure
                    }
                }
        }
    }
}

/*
 * Maps an icon information from the API to a local char
 * Source: http://openweathermap.org/weather-conditions
 */
public func iconNameToChar(icon: String) -> String {
    switch icon {
    case "01d":
        return "\u{f11b}"
    case "01n":
        return "\u{f110}"
    case "02d":
        return "\u{f112}"
    case "02n":
        return "\u{f104}"
    case "03d", "03n":
        return "\u{f111}"
    case "04d", "04n":
        return "\u{f111}"
    case "09d", "09n":
        return "\u{f116}"
    case "10d", "10n":
        return "\u{f113}"
    case "11d", "11n":
        return "\u{f10d}"
    case "13d", "13n":
        return "\u{f119}"
    case "50d", "50n":
        return "\u{f10e}"
    default:
        return "E"
    }
}
