import UIKit
import Photos
import RxSwift

extension PhotosViewController {
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        /*
         这是一个同步的方法, 返回的是 Phasset 对象. Phasset 对象, 是一个数据盒子, 包含的都是关于图片的元信息, 所以, 是一个同步方法.
         */
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
}

class PhotosViewController: UICollectionViewController {
    
    // MARK: public properties
    //
    var selectedPhotos: Observable<UIImage> {
        return selectedPhotosSubject.asObservable()
    }
    
    // 对于模块内来说, 需要使用 Subject 这种类型, 做真正的成员变量的保存工作.
    // Subject 其实就是普通的变量, 实现了 Observable, Observer 的两套接口.
    
    /*
     Subject, 是命令式世界转向响应式世界的接口.
     实际上, 不可避免的还是要使用各种命令式的 API, 但是我们要暴露响应式的接口给外界.
     所以, 只要能够在自己的业务模块里面, hold 的住, 那么还是在命令式世界还是可以的. 但是, 总要有一个办法, 进行响应式的触发.
     Subject 就是完美可以干这个事情的.
     */
    
    /*
     Subject 比较特殊, 它在整个 PineLine 中, 有可能是头结点, 也有可能是中间节点.
     如果是中间节点, 不会出现自己内存消亡的情况. 如果是头结点, 比如现在的情况, 可能会自己先消亡.
     但是 Subject 的 deinit 不会触发 complete 信号. 这个信号, 还是要专门的触发一下才可以 .
     */
    private let selectedPhotosSubject = PublishSubject<UIImage>()
    
    // 不可能脱离原有命令式的世界的, 还是需要使用系统 Api, 进行数据的加载工作.
    private lazy var photos = PhotosViewController.loadPhotos()
    // 真正的, 用来进行图片获取的工具类.
    // 使用这个工具类, 进行图片的读取, 在实现的内部, 会将图片, 进行手机上的存储.
    private lazy var imageManager = PHCachingImageManager()
    
    private lazy var thumbnailSize: CGSize = {
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    // 在界面结束的时候, 主动发送了结束的事件.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedPhotosSubject.onCompleted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: UICollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = photos.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // 异步操作的经典的判断套路, 将, cell 的当前环境, 和异步提交的时候的环境做比较.
            // 如果一致, 就做 UI 的刷新操作.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos.object(at: indexPath.item)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
            cell.flash()
        }
        
        imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
            guard let image = image,
                  let info = info else { return }
            
            if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as?
                Bool, !isThumbnail {
                
                // 在点击了之后, 主动发出信号.
                // 其实, 就是通知外界, 新的图片被选中了. 不过使用信号的这种方式, 将交互这件事, 做到了机制上的统一.
                self?.selectedPhotosSubject.onNext(image)
            }
        })
    }
}
