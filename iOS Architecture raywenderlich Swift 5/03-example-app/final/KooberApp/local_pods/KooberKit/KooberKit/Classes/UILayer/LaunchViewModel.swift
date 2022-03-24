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
    
    public var errorMessages: Observable<ErrorMessage> {
        return self.errorMessagesSubject.asObserver()
    }
    
    private let errorMessagesSubject: PublishSubject<ErrorMessage> =
    PublishSubject()
    
    public let errorPresentation: BehaviorSubject<ErrorPresentation?> =
    BehaviorSubject(value: nil)
    
    // MARK: - Methods
    public init(userSessionRepository: UserSessionRepository,
                notSignedInResponder: NotSignedInResponder,
                signedInResponder: SignedInResponder) {
        self.userSessionRepository = userSessionRepository
        self.notSignedInResponder = notSignedInResponder
        self.signedInResponder = signedInResponder
    }
    
    public func loadUserSession() {
        userSessionRepository.readUserSession()
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
        switch userSession {
        case .none:
            notSignedInResponder.notSignedIn()
        case .some(let userSession):
            signedInResponder.signedIn(to: userSession)
        }
    }
}
