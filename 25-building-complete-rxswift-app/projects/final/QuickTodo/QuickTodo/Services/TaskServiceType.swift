import Foundation
import RxSwift
import RealmSwift

enum TaskServiceError: Error {
  case creationFailed
  case updateFailed(TaskItem)
  case deletionFailed(TaskItem)
  case toggleFailed(TaskItem)
}

// 如果, 不习惯于这种抽象数据类型的创建, 那么这样做就显得是多此一举.
// 但是如果习惯了, 那么之后用到 Task 的地方, 都会是 TaskServiceType 这种抽象数据类型.
// 在这个项目里面, 所有使用的地方, 都是 TaskServiceType 这个抽象类型, 而不是 TaskService 这个具体的类型.

/*
 这种抽象数据类型, 其实有个好处, 就是让使用者能够好好写代码了.
 如果是 TaskService 直接被使用, 使用者可以随意调用 TaskService 的方法, 这会污染 TaskService 的状态的.
 所以好处是:
 1. 抽象数据类型的实现者, 可以将自身的状态管理进行隐藏, 隐隐暴露对方需要的接口. 在这些接口里面, 由外界触发状态的管理工作. 这会减少状态被污染的几率.
 2. 抽象数据类型的使用者, 可以减少自身对于工具对象的理解难度, 在合适的地方, 调用工具对象的方法就可以了. 这样, 也避免了污染工具对象的状态. 减少了程序的出错效率. 
 */
protocol TaskServiceType {
  
  @discardableResult
  func createTask(title: String) -> Observable<TaskItem>
  
  @discardableResult
  func delete(task: TaskItem) -> Observable<Void>
  
  @discardableResult
  func update(task: TaskItem, title: String) -> Observable<TaskItem>
  
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem>
  
  func tasks() -> Observable<Results<TaskItem>>
}
