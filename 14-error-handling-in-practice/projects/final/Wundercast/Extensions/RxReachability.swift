import SystemConfiguration
import Foundation
import RxSwift
import RxCocoa

enum Reachability {
    case offline
    case online
    case unknown
    
    init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        
        if !connectionRequired && isReachable {
            self = .online
        } else {
            self = .offline
        }
    }
}

class RxReachability {
    static let shared = RxReachability()
    
    private init() {}
    
    // 网络状态, 是一个应该存储的值.
    // 当新的 Observer 来进行监听的时候, 可以给他当前的状态值.
    private static var _status = BehaviorRelay<Reachability>(value: .unknown)
    
    // 不给外界当前的状态, 仅仅是暴露出一个 Observable<Reachability> 抽象数据类型.
    var status: Observable<Reachability> {
        return RxReachability._status.asObservable().distinctUntilChanged()
    }
    
    // 类方法, 就是全局数据的操作方法.
    // 这里直接就是读取的 BehaviorRelay 里面的值.
    // 再次证明了, BehaviorSubject 应该当做是变量来进行使用.
    class func reachabilityStatus() -> Reachability {
        return RxReachability._status.value
    }
    
    func isOnline() -> Bool {
        switch RxReachability._status.value {
        case .online:
            return true
        case .offline, .unknown:
            return false
        }
    }
    
    private var reachability: SCNetworkReachability?
    
    func startMonitor(_ host: String) -> Bool {
        guard reachability != nil else {
            return true
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        // 无论, 监听的方法如何底层. 但是只要用 Subject 进行监听, 就可以让这个值, 变为事件序列.
        if let reachability = SCNetworkReachabilityCreateWithName(nil, host) {
            SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
                let status = Reachability(reachabilityFlags: flags)
                RxReachability._status.accept(status)
            }, &context)
            
            SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            self.reachability = reachability
            return true
        }
        
        return true
    }
    
    func stopMonitor() {
        if let _reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue);
            reachability = nil
        }
    }
    
}
