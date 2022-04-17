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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 信号的这种机制, 使得回调不用写到一起. 不相关的逻辑, 注册信号的不同回调就可以了.
        // 信号的触发, 导致后面的 UI 更新的逻辑.
        images
            .subscribe(onNext: { [weak imagePreview] photos in
                guard let preview = imagePreview else { return }
                preview.image = photos.collage(size: preview.frame.size)
            })
            .disposed(by: bag)
        
        // 信号的触发, 导致了后面的 UI 更新的
        images
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            })
            .disposed(by: bag)
    }
    
    @IBAction func actionClear() {
        // 各种操作, 是进行信号的发送.
        // 发送之后所有的回调都会触发, 这就是响应式的好处, 逻辑代码可以集中到一个地方.
        // 不然, 触发回调的方法, 要在所有的地方主动调用, 很容易造成逻辑不一致的情况.
        images.accept([])
    }
    
    @IBAction func actionSave() {
        guard let image = imagePreview.image else { return }
        
        PhotoWriter.save(image)
            .asSingle()
        // 只有调用了 asSingle 之后, 才能调用下面的方法.
        // 同时, 他也失去了原有的 subscribe 方法的调用权了
        // Single, 其实并不是一个 Observable, 但是它里面藏了一个 Observable, 它提供了特殊的接口, 来满足它的业务定义.
        // 在这些接口的内部, 还是使用藏了的 Observable 的 Subscribe 方法.
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
        //images.value.append(UIImage(named: "IMG_1907.jpg")!)
        
        let photosViewController = storyboard!.instantiateViewController(
            withIdentifier: "PhotosViewController") as! PhotosViewController
        navigationController!.pushViewController(photosViewController, animated: true)
        
        // Photo 的点击事件, 会发射出新的图片过来.
        // 在它的处理办法里面, 是将新发射的图片, 存储到成员变量 Subject 里面.
        // self.images 链接自己的回调函数.
        
        /*
         整个处理逻辑, 变为了 信号触发, 信号的回调触发, 在信号的回调里面, 引起新的信号的触发,
         整个逻辑处理, 增加了信号这个抽象层, 好处是解耦, 但是增加了理解的难度.
         
         整个逻辑, 是存储在了 selectedPhotos 的内部. 如果 selectedPhotos 消亡了, 引用关系也就消亡了.
         */
        
        // 如果, selectedPhotos 后面直接 subscribe, 那么 AnonymousObserver 可以消亡. 因为 AnonymousObserver 没有生成 Sink 这种自引用对象存在.
        // 但是一旦中间有一个 Sink, 那么后面的 AnonymousObserver 其实是存在 Sink 的 Observer 里面. 这个时候, Sink 是自引用的, 就会导致如果没有 StopEvent, 这个 subscription 就不会被 dispose 了.
        // 那这样就会有循环引用的了.
        photosViewController.selectedPhotos
            .do(onNext: { _ in
            print("Do On Next")
        }).subscribe(
                onNext: { [weak self] newImage in
                    guard let images = self?.images else { return }
                    images.accept(images.value + [newImage])
                },
                onDisposed: {
                    print("completed photo selection")
                }
            )
            .disposed(by: bag)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
        present(alert, animated: true, completion: nil)
    }
    
    // UI 控价的更新. 和 合成 Image 展示 Image 是两码事.
    // 响应式的好处也在这里, 建立多条响应管道, 可以让代码更加的清晰.
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}
