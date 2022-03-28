import Foundation
import Reachability
import RxSwift

extension Reachability {
  enum Errors: Error {
    case unavailable
  }
}

// 第一次看到了, Static 方法的使用.
// extension Reactive where Base: Reachability 和定义分类方法, 没有任何的不同.
extension Reactive where Base: Reachability {
  
  static var reachable: Observable<Bool> {
    
    // 每次调用 reachable, 其实都是生成了一个新的事件序列.
    return Observable.create { observer in
      
      let reachability = Reachability.forInternetConnection()
      
      if let reachability = reachability {
        // 是否在序列开启的时候, 发射当前的状态, 是一个需要考虑的事情. 一般来说, 获取状态之类的事件序列, 应该进行初始状态的发射.
        observer.onNext(reachability.isReachable())
        // 将各个事件的回调, 使用信号的方式, 传输出去.
        // reachableBlock, unreachableBlock 被 reachability 存储, 在 reachability 得到系统的信号回调的时候, 会主动触发这几个 Block, 然后触发信号的发送.
        reachability.reachableBlock = { _ in observer.onNext(true) }
        reachability.unreachableBlock = { _ in observer.onNext(false) }
        // 真正的对于信号的监听, 是在 startNotifier 被调用之后, 才开启的.
        reachability.startNotifier()
      } else {
        observer.onError(Reachability.Errors.unavailable)
      }
      
      // reachability 的生命周期, 其实是靠 Disposables.create 进行维护的.
      // 传递的闭包里面, 维护了 reachability 的生命周期, 而这个闭包的生命周期, 会随着 dispose 函数的调用, 被释放掉.
      // 按照道理来说, reachability 的析构函数, 应该主动调用 stopNotifier, 将自己对于信号的监听暂停.
      // rx 里面有很多的自我生命周期管理的对象, 是否 reachability 这是这样设计的呢.
      // startNotifier 里面进行了自引用, 然后在 stopNotifier 才会进行消除. 也就是说, 只有在明确的调用 stopNotifier 之后, 才会释放 reachability.
      
      // 不过这里可以看到, 使用 Observable.create 其实是可以完成各种各样的自定义信号的发送的.
      // 这里就是使用了一个第三方对象, 进行真正的业务处理, 然后使用这个第三方对象的接口, 进行信号的发送工作.
      // 这个第三方对象, 也是不需要专门进行引用的, 网络请求的时候, dataTask 是在 Session 里面有强引用, 所以一定是网络请求结束 dataTask 的生命周期才会有可能移除 .
      return Disposables.create {
        reachability?.stopNotifier()
      }
    }
  }
}
