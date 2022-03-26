import Foundation
import Unbox
@testable import Tweetie

/*
 将, 所有的数据, 写在一个地方, 方便管理.
 
 Mock 的流程, 其实是有着固定的标准的.
 1. 要有一个接口. 从这里看, 在 YD 网络请求里面, 使用 wrapper 是有必要的. 直接使用 Request, 其实就是缺少了这层抽象.
 不过现在自己的写法, 更多地还是一种工具类的使用方式. 应该是在每一个业务里面, 定义一组接口, 然后 wrapper 实现这个接口.
 从现在看, 只有一个 Wrapper 实现了这个接口, 但是如果按照正常的开发逻辑, 一定可以写 Mock 实现类的, 那么这个接口就不是,
 2. 统一的, 将 Mock 所用到的资源放到一个地方, 进行管理.
 3. 创建各个 Mock 类, 实现接口, 在 Mock 的实现里面, 读取 2 中的数据
 4. 使用依赖注入, 传入 Mock 类. 使用条件编译也好, 或者直接修改在测试的时候传入 Mock 对象也好. 这都是稳定的实现方式.
 Mock 的实现, 也可以被当做合理的代码, 停留在项目里面了. 如果为了性能, 可以使用条件编译在 Release 的时候不参与编译就好.
 使用这种开发模式, 再也不会出现, 临时 Mock 数据, 然后删除, 再次想要 Mock 的时候, 还要重新查找 Mock 数据的尴尬了.
 
 
 */
class TestData {
  
  static let listId: ListIdentifier = (username:"user" , slug: "slug")
  
  static let personJSON: [String: Any] = [
    "id": 1,
    "name": "Name",
    "screen_name": "ScreeName",
    "description": "Description",
    "url": "url",
    "profile_image_url_https": "profile_image_url_https",
  ]
  
  static var personUserObject: User {
    return (try! unbox(dictionary: personJSON))
  }
  
  static let tweetJSON: [String: Any] = [
    "id": 1,
    "text": "Text",
    "user": [
      "name": "Name",
      "profile_image_url_https": "Url"
    ],
    "created_at": "Mon Oct 22 11:54:26 +0000 2007"
  ]
  
  static var tweetsJSON: [[String: Any]] {
    return (1...3).map {
      var dict = tweetJSON
      dict["id"] = $0
      return dict
    }
  }
  
  static var tweets: [Tweet] {
    return try! unbox(dictionaries: tweetsJSON, allowInvalidElements: true) as [Tweet]
  }
}
