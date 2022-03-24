import Foundation
import PromiseKit
import RxSwift

// ViewModel, 是 Controller 层的.
// 所以在里面, 有各种的逻辑操作, 是正常的. 
public class LaunchViewModel {
    
    // MARK: - Properties
    let userSessionRepository: UserSessionRepository
    let notSignedInResponder: NotSignedInResponder
    let signedInResponder: SignedInResponder
    
    // 对外暴露的, 是简单的 Observable 对象, 固定好了 Ele 的类型.
    // 内部的 Subject 不进行暴露.
    public var errorMessages: Observable<ErrorMessage> {
        return self.errorMessagesSubject.asObserver()
    }
    
    private let errorMessagesSubject: PublishSubject<ErrorMessage> = PublishSubject()
    
    public let errorPresentation: BehaviorSubject<ErrorPresentation?> = BehaviorSubject(value: nil)
    
    // MARK: - Methods
    public init(userSessionRepository: UserSessionRepository,
                notSignedInResponder: NotSignedInResponder,
                signedInResponder: SignedInResponder) {
        self.userSessionRepository = userSessionRepository
        self.notSignedInResponder = notSignedInResponder
        self.signedInResponder = signedInResponder
    }
    
    // Model Action. 触发 Model 的改变, 然后发送信号.
    public func loadUserSession() {
        // Done 代表着, 没有后续的 Then 需要进行添加了. 所以, Promise 中绑定的值是 Void
        // Done 应该算作 Promise 响应链的最后一条, 正常的业务处理逻辑.
        userSessionRepository.readUserSession()
        // goToNextScreen(userSession:) 是接收 UserSession? 当做参数的对象, 直接在 Done 中使用.
            .done(goToNextScreen(userSession:))
            .catch { error in
                let errorMessage = ErrorMessage(title: "Sign In Error",
                                                message: "Sorry, we couldn't determine if you are already signed in. Please sign in or sign up.")
                self.present(errorMessage: errorMessage)
            }
    }
    
    func present(errorMessage: ErrorMessage) {
        goToNextScreenAfterErrorPresentation()
        errorMessagesSubject.onNext(errorMessage)
    }
    
    func goToNextScreenAfterErrorPresentation() {
        _ = errorPresentation
            .filter { $0 == .dismissed }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.goToNextScreen(userSession: nil)
            })
    }
    
    func goToNextScreen(userSession: UserSession?) {
        // 这里, 使用了 Optional 的最原始的判断方法.
        switch userSession {
        case .none:
            notSignedInResponder.notSignedIn()
        case .some(let userSession):
            signedInResponder.signedIn(to: userSession)
        }
    }
}
