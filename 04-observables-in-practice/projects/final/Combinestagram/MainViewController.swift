import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    private let bag = DisposeBag()
    // 可以看到, 在教材里面, 也没有使用 Singal, 或者 Publisher 这样特殊的概念去命名变量.
    // 就是当做普通的成员变量在使用.
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
        // 由于 Images 是一个 BehaviorValue, 所以在第一次 subscribe 的时候, 也能触发里面的 next closure 逻辑
        // 这就使得构建监听和实际监听, 是同样的一套逻辑. 更新逻辑在统一的地方.
        // 这和自己, ViewDidLoad 里面, 调用 update, 和各种 Model 修改之后, 调用 update, 是同样的一套思路.
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
        
        /*
         原有的异步操作, 也变为了返回一个 Observable 的方式. 通过注册回调, 使得这个异步操作, 可以构建出多个 PipeLine.
         不同的回调, 分别注册, 使得回调这件事, 不在需要单一的入口, 代码组织起来更加的清晰. 当然, 也不好追踪了.
         
         这是一种统一的进行交互的方式, 不论同步异步, 数据格式, 都可以封装成为这样的方式 .
         */
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
        
        // 就和信号槽机制一样. 这是一种统一进行对象之间交互的方式.
        // 不用再有 delegate, notification, block 的注册 各种各样触发回调的方式了.
        // 也不会有内存问题. photosViewController 和 self 没有引用关系, 各种内存, 都是在 selectedPhotos 进行引用. 
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
