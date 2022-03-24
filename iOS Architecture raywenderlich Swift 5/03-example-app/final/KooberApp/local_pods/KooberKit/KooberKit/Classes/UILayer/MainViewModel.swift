
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
    
    public func notSignedIn() {
        viewSubject.onNext(.onboarding)
    }
    
    public func signedIn(to userSession: UserSession) {
        viewSubject.onNext(.signedIn(userSession: userSession))
    }
}
