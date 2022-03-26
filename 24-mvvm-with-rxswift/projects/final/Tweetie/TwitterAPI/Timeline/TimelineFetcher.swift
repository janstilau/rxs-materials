import Foundation

import RxSwift
import RxCocoa
import RxRealm

import RealmSwift
import Reachability
import Unbox

class TimelineFetcher {
  
  private let timerDelay = 30
  private let bag = DisposeBag()
  private let feedCursor = BehaviorRelay<TimelineCursor>(value: .none)
  
  // MARK: input
  let paused = BehaviorRelay<Bool>(value: false)
  
  // MARK: output
  let timeline: Observable<[Tweet]>
  // MARK: Init with list or user
  
  //provide list id to fetch list's tweets
  convenience init(account: Driver<TwitterAccount.AccountStatus>, list: ListIdentifier, apiType: TwitterAPIProtocol.Type) {
    self.init(account: account, jsonProvider: apiType.timeline(of: list))
  }
  
  //provide username to fetch user's tweets
  convenience init(account: Driver<TwitterAccount.AccountStatus>, username: String, apiType: TwitterAPIProtocol.Type) {
    self.init(account: account, jsonProvider: apiType.timeline(of: username))
  }
  
  private init(account: Driver<TwitterAccount.AccountStatus>,
               jsonProvider: @escaping (AccessToken, TimelineCursor) -> Observable<[JSONObject]>) {
    
    // 传入的是一个 Publihser, 根据 Publisher 构建出了符合自己的业务含义的新的 Publisher.
    let currentAccount: Observable<AccessToken> = account
      .filter { account in
        switch account {
        case .authorized: return true
        default: return false
        }
      }
      .map { account -> AccessToken in
        switch account {
        case .authorized(let acaccount):
          return acaccount
        default: fatalError()
        }
      }
      .asObservable()
    
    // timer that emits a reachable logged account
    // Combine 里面, 除了定时器, 其他的都是有着初始值的.
    // 所以这种写法, 其实就是, 判断是否登录, 是否停止, 是否网络连接, 后, 进行网络请求.
    // 如果登录改变, 网络改变, Pause 改变, 都会触发这个 Check 函数.
    // 如果时间到了, 也会触发这个 Check 函数.
    // 也就是说, 如果有着多场景触发同一个函数的情况, 那么使用 combineLates 其实是非常好的. 这可以当做是, combineLastst 的标志.
    let reachableTimerWithAccount = Observable.combineLatest(
      Observable<Int>.timer(.seconds(0), period: .seconds(timerDelay), scheduler: MainScheduler.instance),
      Reachability.rx.reachable,
      currentAccount,
      paused.asObservable(),
      resultSelector: { _, reachable, account, paused in
        return (reachable && !paused) ? account : nil
      })
      .filter { $0 != nil }
      .map { $0! }
    
    let feedCursor = BehaviorRelay<TimelineCursor>(value: .none)
    
    // Re-fetch the timeline
    
    // WithLatest 可以认为是 CombineLast 的简化版本,
    // 被 With 的事件序列, 是没有办法触发事件的流转的, 它仅仅是触发记录当前自己值的操作 .
    // 真正能够触发操作节点的, 还是 Source0 的作用.
    timeline = reachableTimerWithAccount
      .withLatestFrom(feedCursor.asObservable()) { account, cursor in
        return (account: account, cursor: cursor)
      }
    // Token + Cursor, 触发一个新的网络请求. 返回一个 JSON 数组.
      .flatMapLatest(jsonProvider)
    // 然后使用 Tweet.unboxMany 进行变化成为 Model 数组.
      .map(Tweet.unboxMany)
      .share(replay: 1)
    
    // Store the latest position through timeline
    timeline
      .scan(.none, accumulator: TimelineFetcher.currentCursor)
      .bind(to: feedCursor)
      .disposed(by: bag)
    
    // feedCursor 的生命周期, 其实是在这里被引用住了. 它虽然不是一个成员变量, 但一直会随着响应链条的生命周期存在. 
  }
  
  static func currentCursor(lastCursor: TimelineCursor,
                            tweets: [Tweet]) -> TimelineCursor {
    return tweets.reduce(lastCursor) { status, tweet in
      let max: Int64 = tweet.id < status.maxId ? tweet.id-1 : status.maxId
      let since: Int64 = tweet.id > status.sinceId ? tweet.id : status.sinceId
      return TimelineCursor(max: max, since: since)
    }
  }
}
