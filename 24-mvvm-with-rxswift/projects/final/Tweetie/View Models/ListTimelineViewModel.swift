import Foundation

import RealmSwift
import RxSwift
import RxRealm
import RxCocoa

class ListTimelineViewModel {
  
  private let bag = DisposeBag()
  
  private let fetcher: TimelineFetcher
  
  let list: ListIdentifier // 用户名和密码, ViewModel 里面, 存储的 Model 数据. 
  let account: Driver<TwitterAccount.AccountStatus>
  
  // MARK: - Input
  var paused: Bool = false {
    didSet {
      fetcher.paused.accept(paused)
    }
  }
  
  // MARK: - Output
  private(set) var tweets: Observable<(AnyRealmCollection<Tweet>, RealmChangeset?)>!
  private(set) var loggedIn: Driver<Bool>!
  
  // MARK: - Init
  init(account: Driver<TwitterAccount.AccountStatus>,
       list: ListIdentifier,
       apiType: TwitterAPIProtocol.Type = TwitterAPI.self) {
    
    self.account = account
    self.list = list
    
    // fetch and store tweets
    // 在, TimelineFetcher 的 init 方法里面, 根据 account 的值, 创建了自己的 Publisher.
    // 然后这些当做 fetcher 自己的信号源, 在 ViewModel 中直接使用.
    // 这就是信号的操作. 这样就使得, account 的数据改变引发的信号, 可以出发后面各种各样的业务逻辑.
    // 也让代码的追踪, 变得很空难 .
    fetcher = TimelineFetcher(account: account, list: list, apiType: apiType)
    bindOutput()
    
    fetcher.timeline
      .subscribe(Realm.rx.add(update: .all))
      .disposed(by: bag)
  }
  
  // MARK: - Methods
  // 在 ViewModel 内, 做 Observable 的再加工处理.
  private func bindOutput() {
    // Bind tweets
    guard let realm = try? Realm() else {
      return
    }
    tweets = Observable.changeset(from: realm.objects(Tweet.self))
    
    // Bind if an account is available
    loggedIn = account
      .map { status in
        switch status {
        case .unavailable: return false
        case .authorized: return true
        }
      }
      .asDriver(onErrorJustReturn: false)
  }
}
