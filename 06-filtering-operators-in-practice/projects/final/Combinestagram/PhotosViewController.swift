import UIKit
import Photos
import RxSwift

class PhotosViewController: UICollectionViewController {

  // MARK: public properties
  var selectedPhotos: Observable<UIImage> {
    return selectedPhotosSubject.asObservable()
  }

  // MARK: private properties
  private let selectedPhotosSubject = PublishSubject<UIImage>()

  // 这是 Lazy 的, 但是, collectionView 的数据源里面用到了, 不会显示之后立马就进行了使用了吗.
  private lazy var photos = PhotosViewController.loadPhotos()
  private lazy var imageManager = PHCachingImageManager()

  private lazy var thumbnailSize: CGSize = {
    let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    return CGSize(width: cellSize.width * UIScreen.main.scale,
                  height: cellSize.height * UIScreen.main.scale)
  }()

  private let bag = DisposeBag()

  static func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }

  // MARK: View Controller
  override func viewDidLoad() {
    super.viewDidLoad()

    let authorized = PHPhotoLibrary.authorized
      .share()

    // 之所以可以这样的简练, 是因为 Operator 内部, 本身就掺杂了大量的业务逻辑在里面.

    authorized
    // skipWhile, 一直忽略, 如果达到了不用忽略的状态, 后续的就一直不忽略了.
      .skipWhile { !$0 }
    // take, 只获取前面的几个数据, 直到到达了设置的 Count 数量.
      .take(1)
      .subscribe(onNext: { [weak self] _ in
        // 当, 授权到达了 True 状态的时候, 才会触发收集数据, 进行重绘的操作.
        self?.photos = PhotosViewController.loadPhotos()
        DispatchQueue.main.async {
          self?.collectionView?.reloadData()
        }
      })
      .disposed(by: bag)

    authorized
      .skip(1)
      .takeLast(1)
      .filter { !$0 }
      .subscribe(onNext: { [weak self] _ in
        // 当失败了之后, 会触发提示的操作.
        guard let errorMessage = self?.errorMessage else { return }
        DispatchQueue.main.async(execute: errorMessage)
      })
      .disposed(by: bag)
  }

  private func errorMessage() {
    alert(title: "No access to Camera Roll",
          text: "You can grant access to Combinestagram from the Settings app")
      .asObservable()
    // 和 TakeCount 相比, 这个是只关心一定时间内的信号. 
      .take(.seconds(5), scheduler: MainScheduler.instance)
      .subscribe(onCompleted: { [weak self] in
        self?.dismiss(animated: true, completion: nil)
        _ = self?.navigationController?.popViewController(animated: true)
      })
      .disposed(by: bag)
  }

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
        self?.selectedPhotosSubject.onNext(image)
      }
    })
  }
}
