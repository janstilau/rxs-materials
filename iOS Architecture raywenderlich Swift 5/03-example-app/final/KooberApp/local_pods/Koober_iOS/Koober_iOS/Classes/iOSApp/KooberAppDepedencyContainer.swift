import UIKit
import KooberKit
import RxSwift

public class KooberAppDependencyContainer {
    
    // MARK: - Properties
    
    // Long-lived dependencies
    let sharedUserSessionRepository: UserSessionRepository
    let sharedMainViewModel: MainViewModel
    
    // MARK: - Methods
    public init() {
        
        // 通过, 将所有的实际需要的功能类, 接口化, 使得所有需要用到的功能类, 都可以实现依赖注入.
        // 依赖注入有一个前提, 就是面向接口编程. 在被注入的功能实现里面, 使用接口进行方法的调用.
        // 这样, 通过属性设置, 或者 初始化进行接口对象的替换, 才有意义. 
        func makeUserSessionRepository() -> UserSessionRepository {
            let dataStore = makeUserSessionDataStore()
            let remoteAPI = makeAuthRemoteAPI()
            return KooberUserSessionRepository(dataStore: dataStore,
                                               remoteAPI: remoteAPI)
        }
        
        /*
         
         */
        func makeUserSessionDataStore() -> UserSessionDataStore {
            
#if USER_SESSION_DATASTORE_FILEBASED
            return FileUserSessionDataStore()
            
#else
            let coder = makeUserSessionCoder()
            return KeychainUserSessionDataStore(userSessionCoder: coder)
#endif
        }
        
        func makeUserSessionCoder() -> UserSessionCoding {
            return UserSessionPropertyListCoder()
        }
        
        func makeAuthRemoteAPI() -> AuthRemoteAPI {
            return FakeAuthRemoteAPI()
        }
        
        // Because `MainViewModel` is a concrete type
        //  and because `MainViewModel`'s initializer has no parameters,
        //  you don't need this inline factory method,
        //  you can also initialize the `sharedMainViewModel` property
        //  on the declaration line like this:
        //  `let sharedMainViewModel = MainViewModel()`.
        //  Which option to use is a style preference.
        func makeMainViewModel() -> MainViewModel {
            return MainViewModel()
        }
        
        
        
        /*
         在这个库里面, 将所有的 Init 方法, 写在了一起. 最后调用一个函数, 进行数据层的初始化的工作.
         一般不会这样写代码.
         */
        self.sharedUserSessionRepository = makeUserSessionRepository()
        self.sharedMainViewModel = makeMainViewModel()
    }
    
    // Main
    // Factories needed to create a MainViewController.
    
    public func makeMainViewController() -> MainViewController {
        let launchViewController = makeLaunchViewController()
        
        let onboardingViewControllerFactory = {
            return self.makeOnboardingViewController()
        }
        
        let signedInViewControllerFactory = { (userSession: UserSession) in
            return self.makeSignedInViewController(session: userSession)
        }
        
        return MainViewController(viewModel: sharedMainViewModel,
                                  launchViewController: launchViewController,
                                  onboardingViewControllerFactory: onboardingViewControllerFactory,
                                  signedInViewControllerFactory: signedInViewControllerFactory)
    }
    
    // Launching
    
    public func makeLaunchViewController() -> LaunchViewController {
        return LaunchViewController(launchViewModelFactory: self)
    }
    
    public func makeLaunchViewModel() -> LaunchViewModel {
        return LaunchViewModel(userSessionRepository: sharedUserSessionRepository,
                               notSignedInResponder: sharedMainViewModel,
                               signedInResponder: sharedMainViewModel)
    }
    
    // Onboarding (signed-out)
    // Factories needed to create an OnboardingViewController.
    
    public func makeOnboardingViewController() -> OnboardingViewController {
        let dependencyContainer = KooberOnboardingDependencyContainer(appDependencyContainer: self)
        return dependencyContainer.makeOnboardingViewController()
    }
    
    // Signed-in
    
    public func makeSignedInViewController(session: UserSession) -> SignedInViewController {
        let dependencyContainer = makeSignedInDependencyContainer(session: session)
        return dependencyContainer.makeSignedInViewController()
    }
    
    public func makeSignedInDependencyContainer(session: UserSession) -> KooberSignedInDependencyContainer  {
        return KooberSignedInDependencyContainer(userSession: session, appDependencyContainer: self)
    }
}

extension KooberAppDependencyContainer: LaunchViewModelFactory {}
