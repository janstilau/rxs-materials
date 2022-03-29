import UIKit

// 简单的一个 Cell 类, 可以看到, 通过 Model 进行 UI 刷新, 是一个常见的行为. 
class EventCell : UITableViewCell {
  
  @IBOutlet var title: UILabel!
  @IBOutlet var date: UILabel!
  @IBOutlet var details: UILabel!
  
  
  func configure(event: EOEvent) {
    title.text = event.title
    details.text = event.description
    
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    if let when = event.date {
      date.text = formatter.string(for: when)
    } else {
      date.text = ""
    }
  }
}
