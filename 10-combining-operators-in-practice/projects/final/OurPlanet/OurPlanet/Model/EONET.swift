import Foundation
import RxSwift
import RxCocoa

class EONET {
  static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
  static let categoriesEndpoint = "/categories"
  static let eventsEndpoint = "/events"
  
  static var categories: Observable<[EOCategory]> = {
    // 根据返回值的类型, 来锁定了函数内的泛型类型参数.
    let request: Observable<[EOCategory]> = EONET.request(endpoint: categoriesEndpoint,
                                                          contentIdentifier: "categories")
    
    return request
      .map { categories in categories.sorted { $0.name < $1.name } }
      .catchErrorJustReturn([])
      .share(replay: 1, scope: .forever)
  }()
  
  static func jsonDecoder(contentIdentifier: String) -> JSONDecoder {
    let decoder = JSONDecoder()
    // 在 JSONDecoder 里面, 藏了一个值.
    decoder.userInfo[.contentIdentifier] = contentIdentifier
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
  
  static func filteredEvents(events: [EOEvent],
                             forCategory category: EOCategory) -> [EOEvent] {
    return events
      .filter { event in
        return event.categories.contains(
          where: { $0.id == category.id }) &&
        !category.events.contains { $0.id == event.id }
      }
      .sorted(by: EOEvent.compareDates)
  }
  
  static func request<T: Decodable>(endpoint: String,
                                    query: [String: Any] = [:],
                                    contentIdentifier: String) -> Observable<T> {
    do {
      guard let url = URL(string: API)?.appendingPathComponent(endpoint),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
              throw EOError.invalidURL(endpoint)
            }
      
      components.queryItems = try query.compactMap { (key, value) in
        guard let v = value as? CustomStringConvertible else {
          throw EOError.invalidParameter(key, value)
        }
        return URLQueryItem(name: key, value: v.description)
      }
      
      guard let finalURL = components.url else {
        throw EOError.invalidURL(endpoint)
      }
      
      let request = URLRequest(url: finalURL)
      
      return URLSession.shared.rx.response(request: request)
        .map { (result: (response: HTTPURLResponse, data: Data)) -> T in
          // contentIdentifier
          let decoder = self.jsonDecoder(contentIdentifier: contentIdentifier)
          // 在这里, 进行真正的解析动作.
          if let dataString = String.init(data: result.data, encoding: .utf8) {
            print(dataString)
          }
          let envelope = try decoder.decode(EOEnvelope<T>.self, from: result.data)
          return envelope.content
        }
    } catch {
      // 如果上方的代码出错了, 会返回一个 Empty 事件序列.
      return Observable.empty()
    }
  }
  
  /*
   {
     "title": "EONET Event Categories",
     "description": "List of all the available event categories in the EONET system",
     "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories",
     "categories": [
       {
         "id": 6,
         "title": "Drought",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/6",
         "description": "Long lasting absence of precipitation affecting agriculture and livestock, and the overall availability of food and water.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/6"
       },
       {
         "id": 7,
         "title": "Dust and Haze",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/7",
         "description": "Related to dust storms, air pollution and other non-volcanic aerosols. Volcano-related plumes shall be included with the originating eruption event.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/7"
       },
       {
         "id": 16,
         "title": "Earthquakes",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/16",
         "description": "Related to all manner of shaking and displacement. Certain aftermath of earthquakes may also be found under landslides and floods.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/16"
       },
       {
         "id": 9,
         "title": "Floods",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/9",
         "description": "Related to aspects of actual flooding--e.g., inundation, water extending beyond river and lake extents.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/9"
       },
       {
         "id": 14,
         "title": "Landslides",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/14",
         "description": "Related to landslides and variations thereof: mudslides, avalanche.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/14"
       },
       {
         "id": 19,
         "title": "Manmade",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/19",
         "description": "Events that have been human-induced and are extreme in their extent.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/19"
       },
       {
         "id": 15,
         "title": "Sea and Lake Ice",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/15",
         "description": "Related to all ice that resides on oceans and lakes, including sea and lake ice (permanent and seasonal) and icebergs.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/15"
       },
       {
         "id": 10,
         "title": "Severe Storms",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/10",
         "description": "Related to the atmospheric aspect of storms (hurricanes, cyclones, tornadoes, etc.). Results of storms may be included under floods, landslides, etc.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/10"
       },
       {
         "id": 17,
         "title": "Snow",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/17",
         "description": "Related to snow events, particularly extreme/anomalous snowfall in either timing or extent/depth.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/17"
       },
       {
         "id": 18,
         "title": "Temperature Extremes",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/18",
         "description": "Related to anomalous land temperatures, either heat or cold.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/18"
       },
       {
         "id": 12,
         "title": "Volcanoes",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/12",
         "description": "Related to both the physical effects of an eruption (rock, ash, lava) and the atmospheric (ash and gas plumes).",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/12"
       },
       {
         "id": 13,
         "title": "Water Color",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/13",
         "description": "Related to events that alter the appearance of water: phytoplankton, red tide, algae, sediment, whiting, etc.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/13"
       },
       {
         "id": 8,
         "title": "Wildfires",
         "link": "https://eonet.gsfc.nasa.gov/api/v2.1/categories/8",
         "description": "Wildfires includes all nature of fire, including forest and plains fires, as well as urban and industrial fire events. Fires may be naturally caused or manmade.",
         "layers": "https://eonet.gsfc.nasa.gov/api/v2.1/layers/8"
       }
     ]
   }
   */
  
  private static func events(forLast days: Int,
                             closed: Bool,
                             endpoint: String) -> Observable<[EOEvent]> {
    let query: [String: Any] = [
      "days": days,
      "status": (closed ? "closed" : "open")
    ]
    let request: Observable<[EOEvent]> = EONET.request(endpoint: endpoint, query: query, contentIdentifier: "events")
    return request.catchErrorJustReturn([])
  }
  
  static func events(forLast days: Int = 360, category: EOCategory) -> Observable<[EOEvent]> {
    let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
    let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint)
    
    return Observable.of(openEvents, closedEvents)
    // Merge 不关心顺序, 有可能 openEvents 先返回, 也有可能 closedEvents 先返回.
      .merge()
      .reduce([]) { running, new in
        running + new
      }
  }
}
