import UIKit
import KooberUIKit
import PromiseKit
import KooberKit
import RxSwift

public class MainViewController: NiblessViewController {
    
    // MARK: - Properties
    // View Model
    let viewModel: MainViewModel
    
    // Child View Controllers
    let launchViewController: LaunchViewController
    var signedInViewController: SignedInViewController?
    var onboardingViewController: OnboardingViewController?
    
    // State
    let disposeBag = DisposeBag()
    
    // Factories
    let makeOnboardingViewController: () -> OnboardingViewController
    let makeSignedInViewController: (UserSession) -> SignedInViewController
    
    // MARK: - Methods
    public init(viewModel: MainViewModel,
                launchViewController: LaunchViewController,
                onboardingViewControllerFactory: @escaping () -> OnboardingViewController,
                signedInViewControllerFactory: @escaping (UserSession) -> SignedInViewController) {
        self.viewModel = viewModel
        self.launchViewController = launchViewController
        self.makeOnboardingViewController = onboardingViewControllerFactory
        self.makeSignedInViewController = signedInViewControllerFactory
        
        super.init()
    }
    
    public func present(_ view: MainView) {
        switch view {
        case .launching:
            presentLaunching()
        case .onboarding:
            if onboardingViewController?.presentingViewController == nil {
                if presentedViewController.exists {
                    // Dismiss profile modal when signing out.
                    dismiss(animated: true) { [weak self] in
                        self?.presentOnboarding()
                    }
                } else {
                    presentOnboarding()
                }
            }
        case .signedIn(let userSession):
            presentSignedIn(userSession: userSession)
        }
    }
    
    public func presentLaunching() {
        addFullScreen(childViewController: launchViewController)
    }
    
    public func presentOnboarding() {
        let onboardingViewController = makeOnboardingViewController()
        present(onboardingViewController, animated: true) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.remove(childViewController: strongSelf.launchViewController)
            if let signedInViewController = strongSelf.signedInViewController {
                strongSelf.remove(childViewController: signedInViewController)
                strongSelf.signedInViewController = nil
            }
        }
        self.onboardingViewController = onboardingViewController
    }
    
    public func presentSignedIn(userSession: UserSession) {
        remove(childViewController: launchViewController)
        
        let signedInViewControllerToPresent: SignedInViewController
        if let vc = self.signedInViewController {
            signedInViewControllerToPresent = vc
        } else {
            signedInViewControllerToPresent = makeSignedInViewController(userSession)
            self.signedInViewController = signedInViewControllerToPresent
        }
        
        addFullScreen(childViewController: signedInViewControllerToPresent)
        
        if onboardingViewController?.presentingViewController != nil {
            onboardingViewController = nil
            dismiss(animated: true)
        }
    }
    
    // 一般来说, 是在 ViewDidLoad 中, 做 ViewModel 的信号的绑定的动作.
    // 这里是监听 ViewModel 的状态变化, 进行指令式的弹出的动作.
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.view
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] view in
                guard let strongSelf = self else { return }
                strongSelf.present(view)
            })
            .disposed(by: disposeBag)
    }
}
