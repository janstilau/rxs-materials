import Foundation

import RxSwift
import RxCocoa

import Alamofire

typealias JSONObject = [String: Any]

typealias ListIdentifier = (username: String, slug: String)

// 这里返回的是一个闭包. 所以这里是一个工厂.
protocol TwitterAPIProtocol {
  static func timeline(of username: String) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]>
  static func timeline(of list: ListIdentifier) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]>
  static func members(of list: ListIdentifier) -> (AccessToken) -> Observable<[JSONObject]>
}

struct TwitterAPI: TwitterAPIProtocol {
  
  // MARK: - API Addresses
  // 将, 所有的请求, 使用 enum 进行了管理.
  // 这个 Enum 里面, 也是使用了 baseURL + Path 的实现方案.
  fileprivate enum Address: String {
    case timeline = "statuses/user_timeline.json"
    case listFeed = "lists/statuses.json"
    case listMembers = "lists/members.json"
    
    private var baseURL: String {
      return "https://api.twitter.com/1.1/"
    }
    
    var url: URL {
      return URL(string: baseURL.appending(rawValue))!
    }
  }
  
  // MARK: - API errors
  enum Errors: Error {
    case requestFailed
  }
  
  // MARK: - API Endpoint Requests
  static func timeline(of username: String) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]> {
    return { account, cursor in
      return request(account,
                     address: TwitterAPI.Address.timeline,
                     parameters: ["screen_name": username, "contributor_details": "false", "count": "100", "include_rts": "true"])
    }
  }
  
  static func timeline(of list: ListIdentifier) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]> {
    return { account, cursor in
      var params = ["owner_screen_name": list.username, "slug": list.slug]
      if cursor != TimelineCursor.none {
        params["max_id"]   = String(cursor.maxId)
        params["since_id"] = String(cursor.sinceId)
      }
      return request(
        account,
        address: TwitterAPI.Address.listFeed,
        parameters: params)
    }
  }
  
  static func members(of list: ListIdentifier) -> (AccessToken) -> Observable<[JSONObject]> {
    return { account in
      let params = ["owner_screen_name": list.username,
                    "slug": list.slug,
                    "skip_status": "1",
                    "include_entities": "false",
                    "count": "100"]
      let response: Observable<JSONObject> = request(
        account,
        address: TwitterAPI.Address.listMembers,
        parameters: params)
      
      return response
        .map { result in
          guard let users = result["users"] as? [JSONObject] else {return []}
          return users
        }
    }
  }
  
  // 因为 Swift 里面, 返回值的类型, 也可以确定泛型类型. 所以, 这里没有明显的根据参数推断 T 的过程.
  // 因为, Publisher 天然的带有 Success,(next+complete) Fail(error) 的设计, 所以返回一个 Publisher 是一种通用的设计.
  static private func request<T: Any>(_ token: AccessToken,
                                      address: Address,
                                      parameters: [String: String] = [:]) -> Observable<T> {
    return Observable.create { observer in
      var comps = URLComponents(string: address.url.absoluteString)!
      comps.queryItems = parameters.sorted{ $0.0 < $1.0 }.map(URLQueryItem.init)
      let url = try! comps.asURL()
      
      /*
       如果, 是使用的是本地数据, 那么直接使用文件里面的数据进行数据的加载, 然后发射 next+comlete 就可以了.
       */
      guard !TwitterAccount.isLocal else {
        if let cachedFileURL = Bundle.main.url(forResource: url.safeLocalRepresentation.lastPathComponent, withExtension: nil),
           /*
            https://api.twitter.com/1.1/lists/statuses.json?owner_screen_name=icanzilb&slug=RxSwift
            
            file:///private/var/containers/Bundle/Application/3D8F267C-A1A4-4653-8B58-196AA7B40A4C/Tweetie.app/statuses.json-owner_screen_name-icanzilb-slug-RxSwift
            */
           let data = try? Data(contentsOf: cachedFileURL),
           // 这里的 as? 可以进行 T 的确认. 其实 JSONObject 就是 [String: Any]
           let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? T) as T??),
           let result = json {
          observer.onNext(result)
        }
        observer.onCompleted()
        return Disposables.create()
      }
      
      // 所有的数据, 都编码到了 URL 里面.
      let request = Alamofire.request(url.absoluteString,
                                      method: .get,
                                      parameters: Parameters(),
                                      encoding: URLEncoding.httpBody,
                                      headers: ["Authorization": "Bearer \(token)"])
      
      request.responseJSON { response in
        guard response.error == nil,
              let data = response.data,
              let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? T) as T??),
              let result = json else {
                observer.onError(Errors.requestFailed)
                return
              }
        
        observer.onNext(result)
        observer.onCompleted()
      }
      
      return Disposables.create {
        request.cancel()
      }
    }
  }
}

extension String {
  var safeFileNameRepresentation: String {
    return replacingOccurrences(of: "?", with: "-")
      .replacingOccurrences(of: "&", with: "-")
      .replacingOccurrences(of: "=", with: "-")
  }
}

extension URL {
  var safeLocalRepresentation: URL {
    return URL(string: absoluteString.safeFileNameRepresentation)!
  }
}
