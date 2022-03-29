import UIKit
import RxSwift
import RxCocoa
import Kingfisher

func cachedFileURL(_ fileName: String) -> URL {
  return FileManager.default
    .urls(for: .cachesDirectory, in: .allDomainsMask)
    .first!
    .appendingPathComponent(fileName)
}

class ActivityController: UITableViewController {
  private let repo = "ReactiveX/RxSwift"
  
  private let events = BehaviorRelay<[Event]>(value: [])
  private let bag = DisposeBag()
  
  private let eventsFileURL = cachedFileURL("events.json")
  private let modifiedFileURL = cachedFileURL("modified.txt")
  
  private let lastModified = BehaviorRelay<String?>(value: nil)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = repo
    
    self.refreshControl = UIRefreshControl()
    let refreshControl = self.refreshControl!
    
    refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
    refreshControl.tintColor = UIColor.darkGray
    refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    
    // 在界面出现的时候, 进行缓存数据的读取, 这样可以快速的进行界面的展示.
    let decoder = JSONDecoder()
    if let eventsData = try? Data(contentsOf: eventsFileURL),
       let persistedEvents = try? decoder.decode([Event].self, from: eventsData) {
      events.accept(persistedEvents)
    }
    
    // 在界面的时候, 进行缓存数据的读取, 确保后续刷新可以在锚点之后进行.
    if let lastModifiedString = try? String(contentsOf: modifiedFileURL, encoding: .utf8) {
      lastModified.accept(lastModifiedString)
    }
    
    refresh()
  }
  
  @objc func refresh() {
    DispatchQueue.global(qos: .default).async { [weak self] in
      guard let self = self else { return }
      self.fetchEvents(repo: self.repo)
    }
  }
    
  // 真正的网络交互的触发.
  // 在这里大量的使用了 flatMap, 触发新的事件序列.
  func fetchEvents(repo: String) {
    let response = Observable.from([repo])
      .map { urlString -> URL in
        // 使用 map, 得到真正的 URL 对象, 作为后面触发网络请求的 URL.
        return URL(string: "https://api.github.com/repos/\(urlString)/events")!
      }
    // 使用 map, 将 URL 对象, 构建成为一个 URLRequest 对象.
      .map { [weak self] url -> URLRequest in
        var request = URLRequest(url: url)
        // 这是那个锚点值, 根据这个值, 可以拉取列表某个点之后的数据.
        if let modifiedHeader = self?.lastModified.value {
          request.addValue(modifiedHeader,
                           forHTTPHeaderField: "Last-Modified")
        }
        return request
      }
    // 真正的触发网络请求的, 在 FlatMap 的内部.
      .flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
        return URLSession.shared.rx.response(request: request)
      }
      .share(replay: 1)
    
    // response next 里面包裹的值, 是 (response: HTTPURLResponse, data: Data) 这个值.
    response
    // 首先根据 Code 值, 来过滤一些错误的数据.
      .filter { response, _ in
        return 200..<300 ~= response.statusCode
      }
    // 将 Data 部分, 构建成为 [Event] 的形式.
      .compactMap { _, data -> [Event]? in
        return try? JSONDecoder().decode([Event].self, from: data)
      }
    // 将真正的网络得到的 Model 数据, 交给命令式的世界, 进行处理.
      .subscribe(onNext: { [weak self] newEvents in
        self?.processEvents(newEvents)
      })
      .disposed(by: bag)
    
    // 同样的一个网络请求, 上方是真正的业务数据的处理.
    // 这里是 Last-Modified 的更新.
    // 信号发送注册的方式, 使得业务逻辑的处理, 按照自己的方式进行管理, 而不用所有的东西都写到一个地方.
    response
      .filter { response, _ in
        return 200..<400 ~= response.statusCode
      }
      .flatMap { response, _ -> Observable<String> in
        // 这里使用 map 其实也可以达到要求, 后面增加一个 Filter 的 Operator 就可以.
        // 不过, 使用 flatMap, 使用新的一个事件序列, 也是一个新的方式.
        // 在 rx 里面, 很喜欢这种, trigger 
        guard let value = response.allHeaderFields["Last-Modified"] as? String else {
          return Observable.empty()
        }
        return Observable.just(value)
      }
      .subscribe(onNext: { [weak self] modifiedHeader in
        guard let self = self else { return }
        
        self.lastModified.accept(modifiedHeader)
        try? modifiedHeader.write(to: self.modifiedFileURL, atomically: true, encoding: .utf8)
      })
      .disposed(by: bag)
  }
  
  func processEvents(_ newEvents: [Event]) {
    var updatedEvents = newEvents + events.value
    if updatedEvents.count > 50 {
      updatedEvents = [Event](updatedEvents.prefix(upTo: 50))
    }
    
    // 真正的触发 dataSource 的更新操作.
    // 然后进行 TableView 的刷新.
    events.accept(updatedEvents)
    DispatchQueue.main.async {
      self.tableView.reloadData()
      self.refreshControl?.endRefreshing()
    }
    
    // 然后, 对现在的数据进行缓存.
    let encoder = JSONEncoder()
    if let eventsData = try? encoder.encode(updatedEvents) {
      try? eventsData.write(to: eventsFileURL, options: .atomicWrite)
    }
  }
  
  // MARK: - Table Data Source
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return events.value.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let event = events.value[indexPath.row]
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
    cell.textLabel?.text = event.actor.name
    cell.detailTextLabel?.text = event.repo.name + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
    cell.imageView?.kf.setImage(with: event.actor.avatar, placeholder: UIImage(named: "blank-avatar"))
    return cell
  }
}
