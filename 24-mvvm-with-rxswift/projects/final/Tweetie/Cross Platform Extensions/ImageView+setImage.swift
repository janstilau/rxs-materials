#if os(iOS)
import UIKit
typealias ImageView = UIImageView
typealias Image = UIImage
#endif

#if os(macOS)
import AppKit
typealias ImageView = NSImageView
typealias Image = NSImage
#endif

extension ImageView {
  func setImage(with url: URL?) {
    guard let url = url else {
      image = nil
      return
    }
    
    // 一个简单的进行 ImageView 赋值的分类, 有点浪费性能, 不过, 是一个简单有效的进行下载赋值的思路. 
    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let strongSelf = self else { return }
      URLSession.shared.dataTask(with: url) { data, response, error in
        var result: Image? = nil
        if let data = data, let newImage = Image(data: data) {
          result = newImage
        } else {
          print("Fetch image error: \(error?.localizedDescription ?? "n/a")")
        }
        DispatchQueue.main.async {
          strongSelf.image = result
        }
      }.resume()
    }
  }
}

