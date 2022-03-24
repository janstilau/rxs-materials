import Foundation
import UIKit

/*
 这就是一个 UI 工具类, 不是重点. 
 */
public struct Appearance {
    
    // MARK: Component Theming
    static func applyBottomLine(to view: UIView, color: UIColor = UIColor.ufoGreen) {
        let line = UIView(frame: CGRect(x: 0, y: view.frame.height - 1, width: view.frame.width, height: 1))
        line.backgroundColor = color
        view.addSubview(line)
    }
}
