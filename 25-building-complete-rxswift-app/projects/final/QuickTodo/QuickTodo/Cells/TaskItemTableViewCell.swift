import UIKit
import Action
import RxSwift

class TaskItemTableViewCell: UITableViewCell {
  
  @IBOutlet var title: UILabel!
  @IBOutlet var button: UIButton!
  
  private var disposeBag = DisposeBag()
  
  func configure(with item: TaskItem, action: CocoaAction) {
    
    button.rx.action = action
    
    // 监听了 Item 的 title 的这个属性.
    // 里面使用了 KVO 的机制.
    // 在现实的环境里面, 很少使用 KVO 这种机制在 Swfit 里面. 
    item.rx.observe(String.self, "title")
      .subscribe(onNext: { [weak self] title in
        self?.title.text = title
      })
      .disposed(by: disposeBag)
    
    item.rx.observe(Date.self, "checked")
      .subscribe(onNext: { [weak self] date in
        let image = UIImage(named: date == nil ? "ItemNotChecked" : "ItemChecked")
        self?.button.setImage(image, for: .normal)
      })
      .disposed(by: disposeBag)
  }
  
  override func prepareForReuse() {
    button.rx.action = nil
    disposeBag = DisposeBag()
    super.prepareForReuse()
  }
}
