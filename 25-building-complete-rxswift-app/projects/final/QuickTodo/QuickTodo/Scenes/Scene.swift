
import Foundation

// 从这里看, ViewModel 的创建工作, 是完全的交给了外界. 
enum Scene {
  case tasks(TasksViewModel)
  case editTask(EditTaskViewModel)
}
