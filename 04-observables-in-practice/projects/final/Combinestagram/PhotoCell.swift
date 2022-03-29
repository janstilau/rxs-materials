import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    var representedAssetIdentifier: String!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    // 当, 被点击了之后, 会主动调用该接口, 做一次 Cell 的刷新动作.
    // 视觉效果就是闪光一下. 一般来说, 闪光效果, 就是 alpha 值的变化. 
    func flash() {
        imageView.alpha = 0
        setNeedsDisplay()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.imageView.alpha = 1
        })
    }
}
