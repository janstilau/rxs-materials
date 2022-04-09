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
    // 没有, 在外界创建后传入, 而是将生成方法传入.
    // 如果登录了, 没有必要生成 OnboardingViewController, SignedInViewController
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
    
    public func present(_ view: MainViewState) {
        switch view {
        case .launching:
            presentLaunching()
        case .onboarding:
            // presentingViewController 这个属性, 代表着哪个 VC 把自己弹出来了.
            // 这里的判断, 其实就是判断 onboardingViewController 有没有被弹出. 如果没有被弹出, 指定里面弹出的逻辑.
            if onboardingViewController?.presentingViewController == nil {
                // presentedViewController 这个属性, 代表着自己弹出谁来了.
                // 如果, 弹出了别的 VC, 回落后弹出 OnBoarding
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
    
    // 一定会触发该操作. 把 launchViewController 添加到屏幕上. 
    public func presentLaunching() {
        addFullScreen(childViewController: launchViewController)
    }
    
    public func presentOnboarding() {
        // 因为, onboardingViewController 不一定需要生成, 所以这里传递进来的, 是一个工厂方法.
        // 当真的需要生成的时候, 在进行 onboardingViewController 的生成.
        let onboardingViewController = makeOnboardingViewController()
        // 这里应该是之前的代码, 没有考虑到 iOS Present 的后续变化, 应该添加 FullScreen 的 Present Style 设置.
        onboardingViewController.modalPresentationStyle = .fullScreen
        present(onboardingViewController, animated: true) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            // 弹出登录相关的界面, 然后将其他的界面, 进行 Remove 操作.
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
