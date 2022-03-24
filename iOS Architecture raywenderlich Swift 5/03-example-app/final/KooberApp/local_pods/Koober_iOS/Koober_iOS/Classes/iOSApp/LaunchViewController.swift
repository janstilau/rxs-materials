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
    
    // 内部的 ViewModel, 需要在 Init 中生成, 不直接传入 ViewModel, 而是传入 ViewModel 的工厂类.
    // 没太明白, 这样做的好处在哪里. 
    init(launchViewModelFactory: LaunchViewModelFactory) {
        self.viewModel = launchViewModelFactory.makeLaunchViewModel()
        super.init()
    }
    
    public override func loadView() {
        view = LaunchRootView(viewModel: viewModel)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        observeErrorMessages()
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
