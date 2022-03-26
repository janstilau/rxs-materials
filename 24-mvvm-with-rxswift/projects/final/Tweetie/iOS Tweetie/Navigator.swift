import Foundation
import UIKit

import RxCocoa

/*
 一个类似于 Router 的东西.
 将所有的页面跳转, 用 Router 进行管理. 这样做的好处是, 不需要界面之间, 有互相的依赖了.
 */

/*
 Navigator 需要知道, 所有的 VC 的接口, 创建方式, 这样才可以让各个 VC 之间没有直接的连接.
 
 如果直接使用 Url 的方式, 则是传递 path 和 param, 使用字符串进行传递, 在 Router 的内部, 需要注册某个 Path 应该如何生成 VC, 生成这个 VC 然后返回.
 现在的 YDRouter 的方式, 则是使用 Protocol 的方式, 使用 resolver 通过 Path 找到对应的 Protocol, 然后获取 Protocol 的实现类, 然后使用对应的 Params 使用 Creater 生成对应的 VC, 然后返回. 
 */
class Navigator {
  
  lazy private var defaultStoryboard = UIStoryboard(name: "Main", bundle: nil)
  
  // MARK: - segues list
  enum Segue {
    case listTimeline(Driver<TwitterAccount.AccountStatus>, ListIdentifier)
    case listPeople(Driver<TwitterAccount.AccountStatus>, ListIdentifier)
    case personTimeline(Driver<TwitterAccount.AccountStatus>, username: String)
  }
  
  // MARK: - invoke a single segue
  func show(segue: Segue, sender: UIViewController) {
    switch segue {
    case .listTimeline(let account, let list):
      //show the combined timeline for the list
      let vm = ListTimelineViewModel(account: account, list: list)
      show(target: ListTimelineViewController.createWith(navigator: self, storyboard: sender.storyboard ?? defaultStoryboard, viewModel: vm), sender: sender)
      
    case .listPeople(let account, let list):
      //show the list of user accounts in the list
      let vm = ListPeopleViewModel(account: account, list: list)
      show(target: ListPeopleViewController.createWith(navigator: self, storyboard: sender.storyboard ?? defaultStoryboard, viewModel: vm), sender: sender)
      
    case .personTimeline(let account, username: let username):
      //show a given user timeline
      let vm = PersonTimelineViewModel(account: account, username: username)
      show(target: PersonTimelineViewController.createWith(navigator: self, storyboard: sender.storyboard ?? defaultStoryboard, viewModel: vm), sender: sender)
    }
  }
  
  // 使用 Push 的方式, 将新生成的 VC 进行展示.
  private func show(target: UIViewController, sender: UIViewController) {
    if let nav = sender as? UINavigationController {
      //push root controller on navigation stack
      nav.pushViewController(target, animated: false)
      return
    }
    
    if let nav = sender.navigationController {
      //add controller to navigation stack
      nav.pushViewController(target, animated: true)
    } else {
      //present modally
      sender.present(target, animated: true, completion: nil)
    }
  }
}
