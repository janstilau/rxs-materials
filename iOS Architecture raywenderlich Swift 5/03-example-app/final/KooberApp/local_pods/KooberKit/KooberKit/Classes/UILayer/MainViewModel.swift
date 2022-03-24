
import Foundation
import RxSwift

public class MainViewModel: SignedInResponder, NotSignedInResponder {
    
    // MARK: - Properties
    // 外部使用 Observable<MainView>, 将 Publisher 进行暴露, 外界使用暴露出来的 Publisher, 进行信号的绑定处理.
    public var view: Observable<MainView> { return viewSubject.asObservable() }
    // 内部使用 Subject, 来做状态的管理工作
    private let viewSubject = BehaviorSubject<MainView>(value: .launching)
    
    // MARK: - Methods
    public init() {}
    
    // 这种抽象, 使得代码好混乱.
    // 命名简单的后续流程处理, 中间加了很多抽象层.
    // 关键是, 使用接口编程之后, 后续想要快速定位都很麻烦.
    // LaunchViewModel 根据 UserRepo 进行了用户数据的读写, 然后调用 SignedInResponder, NotSignedInResponder
    // 来触发是否登录的逻辑. 这就来到了 MainViewModel 了.
    // 在这里, 是触发了信号的操作. 信号发射之后, 到底做了什么呢.
    // 需要看 viewSubject 的 connect 函数是怎么写的. 这是在 MainViewController 里面, 在里面, 是根据不同的信号数据, 进行不同的 VC 展示. 
    public func notSignedIn() {
        viewSubject.onNext(.onboarding)
    }
    
    public func signedIn(to userSession: UserSession) {
        viewSubject.onNext(.signedIn(userSession: userSession))
    }
}
