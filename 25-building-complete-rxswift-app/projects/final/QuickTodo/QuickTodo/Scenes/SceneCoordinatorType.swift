import UIKit
import RxSwift

// 设计的不好. 不应该把 Scene 掺杂进来. Scene 是强业务相关的. 
protocol SceneCoordinatorType {
  /// transition to another scene
  @discardableResult
  func transition(to scene: Scene, type: SceneTransitionType) -> Completable
  
  /// pop scene from navigation stack or dismiss current modal
  @discardableResult
  func pop(animated: Bool) -> Completable
}

extension SceneCoordinatorType {
  @discardableResult
  func pop() -> Completable {
    return pop(animated: true)
  }
}
