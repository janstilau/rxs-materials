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
    // 但是, 是
    var selectedPhotos: Observable<UIImage> {
        return selectedPhotosSubject.asObservable()
    }
    
    // 对于模块内来说, 需要使用 Subject 这种类型, 做真正的成员变量的保存工作.
    // Subject 其实就是普通的变量, 实现了 Observable, Observer 的两套接口.
    // 使用 Subject 进行值的变化的时候, 能够主动地进行信号的发送.
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
    // 感觉没有太大必要.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedPhotosSubject.onCompleted()
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
