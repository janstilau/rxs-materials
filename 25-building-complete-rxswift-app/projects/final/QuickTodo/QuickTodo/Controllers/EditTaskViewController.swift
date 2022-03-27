import UIKit
import RxSwift
import RxCocoa
import Action
import NSObject_Rx

// 这里的代码, 着实是有些复杂了. 
class EditTaskViewController: UIViewController, BindableType {
  
  @IBOutlet var titleView: UITextView!
  @IBOutlet var okButton: UIBarButtonItem!
  @IBOutlet var cancelButton: UIBarButtonItem!
  
  var viewModel: EditTaskViewModel!
  
  func bindViewModel() {
    titleView.text = viewModel.itemTitle
    
    cancelButton.rx.action = viewModel.onCancel
    
    okButton.rx.tap
      .withLatestFrom(titleView.rx.text.orEmpty)
      .bind(to: viewModel.onUpdate.inputs)
      .disposed(by: self.rx.disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    titleView.becomeFirstResponder()
  }
  
}
