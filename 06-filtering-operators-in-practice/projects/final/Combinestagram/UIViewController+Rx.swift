import UIKit
import RxSwift

extension UIViewController {
  
  // 将 Alert Action 变为了 Completable
  // 原本的操作, 是 alert 之后, 传递一个闭包过去, 闭包里面, 是按钮点击的后续逻辑.
  // 现在这种闭包, 变为了事件流的传递.
  func alert(title: String, text: String?) -> Completable {
    return Completable.create { [weak self] completable in
      
      let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: {_ in
        completable(.completed)
      }))
      self?.present(alertVC, animated: true, completion: nil)
      return Disposables.create {
        self?.dismiss(animated: true, completion: nil)
      }
    }
  }
}
