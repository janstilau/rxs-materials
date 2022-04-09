import UIKit
import RxSwift
import Then
import Alamofire
import RxRealmDataSources

class ListTimelineViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var messageView: UIView!
  
  private let bag = DisposeBag()
  fileprivate var viewModel: ListTimelineViewModel! // ViewModel.
  fileprivate var navigator: Navigator! // Router 的概念. 外界传递过来的.
  
  static func createWith(navigator: Navigator,
                         storyboard: UIStoryboard,
                         viewModel: ListTimelineViewModel) -> ListTimelineViewController {
    return storyboard.instantiateViewController(ofType: ListTimelineViewController.self).then { vc in
      vc.navigator = navigator
      vc.viewModel = viewModel
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.estimatedRowHeight = 90
    tableView.rowHeight = UITableView.automaticDimension
    title = "@\(viewModel.list.username)/\(viewModel.list.slug)"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: nil, action: nil)
    
    bindUI()
  }
  
  func bindUI() {
    // ViewAction 的处理.
    navigationItem.rightBarButtonItem!.rx.tap
    // 通过 throttle 这个操作符, 将暴力点击进行了规避.
    // 如果不用这个操作符, 那么需要特地编写规避暴力点击的逻辑, 是复杂的.
    // Rx 能够用好的基础, 就是要对 rx 里面, 各个操作符的作用熟悉.
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        guard let self = self else { return }
        // subscibe 一般就是用来连接指令的.
        // 如果是 UI, 那么 Drive, 或者 Bindto 这种, 更加的能够显示 UI 的作用.
        self.navigator.show(segue: .listPeople(self.viewModel.account, self.viewModel.list), sender: self)
      })
      .disposed(by: bag)
    
    // Show tweets in table view
    let dataSource = RxTableViewRealmDataSource<Tweet>(cellIdentifier:
                                                        "TweetCellView",
                                                       cellType: TweetCellView.self) { cell, _, tweet in
      cell.update(with: tweet)
    }
    
    // 在这里, 会实际的触发网络请求. 
    viewModel.tweets
      .bind(to: tableView.rx.realmChanges(dataSource))
      .disposed(by: bag)
    
    // Show message when no account available
    viewModel.loggedIn
      .drive(messageView.rx.isHidden)
      .disposed(by: bag)
  }
}
