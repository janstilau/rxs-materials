import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {
  
  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  
  private let bag = DisposeBag()
  private let images = BehaviorRelay<[UIImage]>(value: [])
  
  private var imageCache = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    images
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak imagePreview] photos in
        guard let preview = imagePreview else { return }
        preview.image = photos.collage(size: preview.frame.size)
      })
      .disposed(by: bag)
    
    images
      .subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .disposed(by: bag)
  }
  
  @IBAction func actionClear() {
    images.accept([])
    imageCache = []
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    PhotoWriter.save(image)
      .subscribe(
        onSuccess: { [weak self] id in
          self?.showMessage("Saved with id: \(id)")
          self?.actionClear()
        },
        onError: { [weak self] error in
          self?.showMessage("Error", description: error.localizedDescription)
        }
      )
      .disposed(by: bag)
  }
  
  @IBAction func actionAdd() {
    // images.accept(images.value + [UIImage(named: "IMG_1907.jpg")!])
    
    let photosViewController = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController
    
    navigationController!.pushViewController(photosViewController, animated: true)
    
    // 通过查看源码, 知道 selectedPhotos 其实是一个 SUBJECT, 而 Subject 是默认具有 share 属性的.
    // 但是, 使用者并不知道, 所以, 在合适的时候, 应该明显的调用 share
    let newPhotos = photosViewController.selectedPhotos
      .share()
    
    newPhotos
    // TakWhile, 当 Predicate return True 的时候, 才会 forward 当前的 event.
      .takeWhile { [weak self] image in
        let count = self?.images.value.count ?? 0
        return count < 6
      }
    // 必须是长方图.
      .filter { newImage in
        return newImage.size.width > newImage.size.height
      }
    // 使用 bytecount 当做了唯一标识符.
      .filter { [weak self] newImage in
        let len = newImage.pngData()?.count ?? 0
        guard self?.imageCache.contains(len) == false else {
          return false
        }
        // 在 Filter 里面, 有副作用.
        // 但是整个数据的流向, 是没有副作用的.
        self?.imageCache.append(len)
        return true
      }
    // 最终的业务处理代码.
      .subscribe(
        onNext: { [weak self] newImage in
          guard let images = self?.images else { return }
          images.accept(images.value + [newImage])
        },
        onDisposed: {
          print("completed photo selection")
        }
      )
      .disposed(by: bag)
    
    newPhotos
    // 这里体现了 ignoreElements 的作用.
    // 不关心 next 事件, 仅仅关心 complete 事件.
    // ignoreElements 后面的所有节点, 仅仅会在 complete 事件中触发操作.
      .ignoreElements()
    // newPhoto VC 在消失的时候, 会发射出 Complete 出来. 所以是在界面回退到上一个页面的时候, 是进行 NavigationBar 的更新.
      .subscribe(onCompleted: { [weak self] in
        self?.updateNavigationIcon()
      })
      .disposed(by: bag)
  }
  
  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                       style: .done, target: nil, action: nil)
  }
  
  func showMessage(_ title: String, description: String? = nil) {
    alert(title: title, text: description)
      .subscribe()
      .disposed(by: bag)
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
}
