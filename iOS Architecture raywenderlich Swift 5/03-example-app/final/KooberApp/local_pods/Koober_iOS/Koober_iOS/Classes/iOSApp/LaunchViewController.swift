import UIKit
import KooberUIKit
import KooberKit
import RxCocoa
import RxSwift

public class LaunchViewController: NiblessViewController {
    
    // MARK: - Properties
    let viewModel: LaunchViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Methods
    
    init(launchViewModelFactory: LaunchViewModelFactory) {
        // 使用工厂类, 来完成 ViewModel 的构建工作.
        self.viewModel = launchViewModelFactory.makeLaunchViewModel()
        super.init()
    }
    
    public override func loadView() {
        view = LaunchRootView(viewModel: viewModel)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        observeErrorMessages()
        // 把 viewModel 的触发, 从 LaunchRootView 的 Init 方法中, 转移到了 VC 中.
        // 在 VC 中, 调用 ViewModel 的 Model Action, 
        viewModel.loadUserSession()
    }
    
    func observeErrorMessages() {
        viewModel
            .errorMessages
            .asDriver { _ in fatalError("Unexpected error from error messages observable.") }
            .drive(onNext: { [weak self] errorMessage in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.present(errorMessage: errorMessage,
                                   withPresentationState: strongSelf.viewModel.errorPresentation)
            })
            .disposed(by: disposeBag)
    }
}

protocol LaunchViewModelFactory {
    func makeLaunchViewModel() -> LaunchViewModel
}
