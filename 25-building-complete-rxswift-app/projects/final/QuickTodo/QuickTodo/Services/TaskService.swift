import Foundation
import RealmSwift
import RxSwift
import RxRealm

/*
 TaskService 是作为 TaskServiceType 的实现者, 其实, 里面数据如何进行的存储它并不是很关心.
 这里是使用了 Realm 这种方式.
 */
/*
 TaskService 对于 TaskServiceType 的实现就是, 先是进行数据库的读写, 然后根据数据库的结果, 返回对应的 Observable.
 */
struct TaskService: TaskServiceType {
  
  init() {
    do {
      let realm = try Realm()
      if realm.objects(TaskItem.self).count == 0 {
        ["Chapter 5: Filtering operators",
         "Chapter 4: Observables and Subjects in practice",
         "Chapter 3: Subjects",
         "Chapter 2: Observables",
         "Chapter 1: Hello, RxSwift"].forEach {
          self.createTask(title: $0)
        }
      }
    } catch _ { }
  }
  
  /*
   WithSth, Action 这种方式, 其实有着固定的实现思路.
   那就是, 在方法的主逻辑里面, 做 WithSth 的获取工作.
   到底 Sth 是新创建出来的, 还是成员变量, 完全没有必要知道, 真正调用这个方法的使用者, 目的就是在于在 action 的内部, 使用一个 Realm 对象而已.
   
   对于异常的处理, 也都是在 do catch 里面进行的捕获, 外界仅仅是需要知道最后的执行结果而已.
   */
  // 这里的 Operation 其实应该不添加, 完全在主逻辑里面没有被用到.
  private func withRealm<T>(_ operation: String,
                            action: (Realm) throws -> T) -> T? {
    do {
      let realm = try Realm()
      return try action(realm)
    } catch let err {
      print("Failed \(operation) realm with error: \(err)")
      return nil
    }
  }
  
  @discardableResult
  func createTask(title: String) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.title = title
      // 这里, 仅仅使用了 try, 是因为在 withRealm 的方法实现里面, 对于 action 进行了处理.
      // 当, 参数是一个 throws 标识的 Block 的时候, 代表着这个传入的 block, 可以在内部进行 throw, 也可以在内部调用 try, 反正自己内部抛出的错误, 会在外界进行捕获.
      try realm.write {
        task.uid = (realm.objects(TaskItem.self).max(ofProperty: "uid") ?? 0) + 1
        realm.add(task)
      }
      // action 成功, 那么就返回 .just(task)
      // 这里有一点问题, 就是 try realm.write 会有一个隐含逻辑, 那就是 result 有可能是 nil 的. 如果没有搞明白 action: (Realm) throws -> T) -> T? 这个函数签名, 那么不能很好地理解这里的代码.
      return .just(task)
    }
    return result ?? .error(TaskServiceError.creationFailed)
  }
  
  @discardableResult
  func delete(task: TaskItem) -> Observable<Void> {
    let result = withRealm("deleting") { realm-> Observable<Void> in
      try realm.write {
        realm.delete(task)
      }
      // Observable<Void> , 返回 Empty, 就是直接只触发 complete 事件.
      return .empty()
    }
    return result ?? .error(TaskServiceError.deletionFailed(task))
  }
  
  @discardableResult
  func update(task: TaskItem, title: String) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      try realm.write {
        task.title = title
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.updateFailed(task))
  }
  
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("toggling") { realm -> Observable<TaskItem> in
      try realm.write {
        if task.checked == nil {
          task.checked = Date()
        } else {
          task.checked = nil
        }
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.toggleFailed(task))
  }
  
  func tasks() -> Observable<Results<TaskItem>> {
    let result = withRealm("getting tasks") { realm -> Observable<Results<TaskItem>> in
      let realm = try Realm()
      let tasks = realm.objects(TaskItem.self)
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
}
