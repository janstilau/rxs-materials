import Foundation
import Reachability
import RxSwift

extension Reachability {
  enum Errors: Error {
    case unavailable
  }
}

// 第一次看到了, Static 方法的使用.
extension Reactive where Base: Reachability {
  
  // 对于, 类.rx 来说, 可以认为就是在上面定义分类方法.
  static var reachable: Observable<Bool> {
    
    // 每次调用 reachable, 其实都是生成了一个新的事件序列.
    return Observable.create { observer in
      
      let reachability = Reachability.forInternetConnection()
      
      if let reachability = reachability {
        // 首先, 将自己当前的状态传输出去.
        observer.onNext(reachability.isReachable())
        // 将各个事件的回调, 使用信号的方式, 传输出去.
        reachability.reachableBlock = { _ in observer.onNext(true) }
        reachability.unreachableBlock = { _ in observer.onNext(false) }
        reachability.startNotifier()
      } else {
        observer.onError(Reachability.Errors.unavailable)
      }
      
      // reachability 的生命周期, 其实是靠 Disposables.create 进行维护的.
      // 传递的闭包里面, 维护了 reachability 的生命周期, 而这个闭包的生命周期, 会随着 dispose 函数的调用, 被释放掉. 
      return Disposables.create {
        reachability?.stopNotifier()
      }
    }
  }
}
