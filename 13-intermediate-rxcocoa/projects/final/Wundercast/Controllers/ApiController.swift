import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import MapKit

class ApiController {
    
    struct Weather: Decodable {
        static let empty = Weather(
            cityName: "Unknown",
            temperature: -1000,
            humidity: 0,
            icon: iconNameToChar(icon: "e"),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        let cityName: String
        let temperature: Int
        let humidity: Int
        let icon: String
        let coordinate: CLLocationCoordinate2D
        
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
    
    static var shared = ApiController()
    
    private let apiKey = "197d815bb621986c704668dde0b27e5d"
    
    // 这种 BaseURL 的设计, 是一种通用的设计.
    // 几乎所有的网络请求库, 都使用了这样的一种设计方式.
    let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!
    
    init() {
        Logging.URLRequests = { request in
            return true
        }
    }
    
    // MARK: - Api Calls
    // 通过城市名, 来访问接口, 获取到最新的 Weather 数据
    func currentWeather(for city: String) -> Observable<Weather> {
        buildRequest(pathComponent: "weather",
                     params: [("q", city)])
            .map { data in
                try JSONDecoder().decode(Weather.self, from: data)
            }
    }
    // 通过经纬度, 来访问接口, 来获取到最新的 Weather 数据.
    func currentWeather(at coordinate: CLLocationCoordinate2D) -> Observable<Weather> {
        buildRequest(pathComponent: "weather",
                     params: [("lat", "\(coordinate.latitude)"),
                              ("lon", "\(coordinate.longitude)")])
        .map { data in
            try JSONDecoder().decode(Weather.self, from: data)
        }
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(method: String = "GET", pathComponent: String, params: [(String, String)]) -> Observable<Data> {
        let url = baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "appid", value: apiKey)
        let unitsQueryItem = URLQueryItem(name: "units", value: "metric")
        /*
         NSURLComponents 这就是一个, 将 URL 进行分割的类.
         可以传入一个完整的 URL, 通过这个类来获取各个部分的内容.
         也可以使用这个类, 逐步添加各个部分的内容, 然后获取最终的 URL 数据.
         */
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
        
        // 通过 NSURLComponents 来获取添加完各种部件内容后, 最终产生的 URL 数据.
        request.url = urlComponents.url!
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        return session.rx.data(request: request)
    }
}

/**
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

private func imageFromText(text: String, font: UIFont) -> UIImage {
    let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    text.draw(at: CGPoint(x: 0, y: 0), withAttributes: [NSAttributedString.Key.font: font])
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image ?? UIImage()
}

extension ApiController.Weather {
    
    // 从 Weather 生成一个在 MapView 上显示的过程. 具体不做研究, 都是命令式的代码. 
    func overlay() -> Overlay {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: coordinate.latitude - 0.25,
                                   longitude: coordinate.longitude - 0.25),
            CLLocationCoordinate2D(latitude: coordinate.latitude + 0.25,
                                   longitude: coordinate.longitude + 0.25)
        ]
        
        let points = coordinates.map { MKMapPoint($0) }
        let rects = points.map { MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }
        let mapRectUnion: (MKMapRect, MKMapRect) -> MKMapRect = { $0.union($1) }
        let fittingRect = rects.reduce(MKMapRect.null, mapRectUnion)
        return Overlay(icon: icon, coordinate: coordinate, boundingMapRect: fittingRect)
    }
    
    class Overlay: NSObject, MKOverlay {
        var coordinate: CLLocationCoordinate2D
        var boundingMapRect: MKMapRect
        let icon: String
        
        init(icon: String, coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = coordinate
            self.boundingMapRect = boundingMapRect
            self.icon = icon
        }
    }
    
    class OverlayView: MKOverlayRenderer {
        var overlayIcon: String
        
        init(overlay:MKOverlay, overlayIcon:String) {
            self.overlayIcon = overlayIcon
            super.init(overlay: overlay)
        }
        
        public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
            let imageReference = imageFromText(text: overlayIcon, font: UIFont(name: "Flaticon", size: 32.0)!).cgImage
            let theMapRect = overlay.boundingMapRect
            let theRect = rect(for: theMapRect)
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -theRect.size.height)
            context.draw(imageReference!, in: theRect)
        }
    }
}
