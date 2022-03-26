import UIKit
import Alamofire

/*
 所有的可以公用的部分, 放在公共的目录里面, 然后 iOS 相关的东西, 写到 iOS 相关的目录里面.
 */

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  let navigator = Navigator()
  
  let account = TwitterAccount().default
  let list = (username: "icanzilb", slug: "RxSwift")
  let testing = NSClassFromString("XCTest") != nil
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if !testing {
      let feedNavigation = window!.rootViewController! as! UINavigationController
      navigator.show(segue: .listTimeline(account, list), sender: feedNavigation)
    }
    return true
  }
}

