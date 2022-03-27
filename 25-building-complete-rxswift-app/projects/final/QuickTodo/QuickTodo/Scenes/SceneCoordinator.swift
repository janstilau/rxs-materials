import UIKit
import RxSwift
import RxCocoa

// SceneCoordinator 实现了 SceneCoordinatorType 接口, 可以看到, 在整个项目里面, 没有使用 SceneCoordinator 对象, 仅仅使用的是 SceneCoordinatorType 的接口.
class SceneCoordinator: SceneCoordinatorType {
  
  private var window: UIWindow
  private var currentViewController: UIViewController
  
  required init(window: UIWindow) {
    self.window = window
    currentViewController = window.rootViewController!
  }
  
  static func actualViewController(for viewController: UIViewController) -> UIViewController {
    if let navigationController = viewController as? UINavigationController {
      return navigationController.viewControllers.first!
    } else {
      return viewController
    }
  }
  
  @discardableResult
  func transition(to scene: Scene, type: SceneTransitionType) -> Completable {
    let subject = PublishSubject<Void>()
    // 实际的, 根据 Scene 创建 vc 的工作, 是交给了 Scene 的扩展.
    let viewController = scene.viewController()
    switch type {
    case .root:
      // 这种很少用, 这种更换 Window 的 RootVc 的操作, 其实是将 App 的内容整体替换.
      // 这是一个费性能的操作.
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      window.rootViewController = viewController
      subject.onCompleted()
      
    case .push:
      guard let navigationController = currentViewController.navigationController else {
        fatalError("Can't push a view controller without a current navigation controller")
      }
      
      // one-off subscription to be notified when push complete
      _ = navigationController.rx.delegate
        .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
        .map { _ in }
        .bind(to: subject)
      // 真正进行了界面切换的逻辑, 在这里.
      navigationController.pushViewController(viewController, animated: true)
      // 然后就是, 对于状态的管理.
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      
    case .modal:
      viewController.modalPresentationStyle = .fullScreen
      currentViewController.present(viewController, animated: true) {
        // Push 的方式, 是因为没有办法拿到 Push 完成的时刻, 才使用了那么复杂的方式. 使用那种方式, 一定是对于 rx 有了深入的了解之后, 才能做这件事情.
        subject.onCompleted()
      }
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
    }
    
    // ignoreElements 就是, 不发送任何的数据, 仅仅发送成功, 或者 error. 这样是符合 Complete 的定义的, 所以, 返回的也就是 Completable 这种类型. 
    return subject.asObservable()
      .take(1)
      .ignoreElements()
  }
  
  @discardableResult
  func pop(animated: Bool) -> Completable {
    let subject = PublishSubject<Void>()
    if let presenter = currentViewController.presentingViewController {
      // dismiss a modal controller
      currentViewController.dismiss(animated: animated) {
        self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
        subject.onCompleted()
      }
    } else if let navigationController = currentViewController.navigationController {
      // navigate up the stack
      // one-off subscription to be notified when pop complete
      _ = navigationController.rx.delegate
        .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
        .map { _ in }
        .bind(to: subject)
      guard navigationController.popViewController(animated: animated) != nil else {
        fatalError("can't navigate back from \(currentViewController)")
      }
      currentViewController = SceneCoordinator.actualViewController(for: navigationController.viewControllers.last!)
    } else {
      fatalError("Not a modal, no navigation controller: can't navigate back from \(currentViewController)")
    }
    return subject.asObservable()
      .take(1)
      .ignoreElements()
  }
}
