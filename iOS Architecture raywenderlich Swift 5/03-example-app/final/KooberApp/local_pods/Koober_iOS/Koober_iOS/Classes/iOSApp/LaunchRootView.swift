import Foundation
import KooberUIKit
import KooberKit

class LaunchRootView: NiblessView {
    
    // MARK: - Properties
    let viewModel: LaunchViewModel
    
    // MARK: - Methods
    init(frame: CGRect = .zero,
         viewModel: LaunchViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        styleView()
        // 这里的代码非常烂. 凭什么要让 ViewModel 的 LoadUserSession 放到 View 的 init 方法中.
        // 这明显就是 Controller 层的事情, 至少也是应该方法 LaunchViewController 中才对.
//        loadUserSession()
    }
    
    private func styleView() {
        backgroundColor = Color.background
    }
    
    private func loadUserSession() {
        viewModel.loadUserSession()
    }
}
