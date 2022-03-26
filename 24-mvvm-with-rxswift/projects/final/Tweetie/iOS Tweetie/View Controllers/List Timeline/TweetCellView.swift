import Foundation
import UIKit

// 这种简单的 View, 就没有必要, 要引入 ViewModel 这一层了.
class TweetCellView: UITableViewCell {
  
  @IBOutlet weak var photo: UIImageView!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var message: UITextView!
  
  func update(with tweet: Tweet) {
    name.text = tweet.name
    message.text = tweet.text
    photo.setImage(with: URL(string: tweet.imageUrl))
  }
}
