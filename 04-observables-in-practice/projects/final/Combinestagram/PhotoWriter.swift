import RxSwift
import Foundation
import UIKit
import Photos

class PhotoWriter {
    enum Errors: Error {
        case couldNotSavePhoto
    }
    
    /*
     这种方式, 作为统一的基础, 是所有的返回值, 是使用 Observable 这种类型.
     因为外界是需要这个返回值, 来注册回调的.
     这其实也就为什么这个框架重的愿意了.
     只要使用了这个框架, 那么所有的接口, 都要使用返回值为 Observable 的形式, 外界模块要和这个库交互的话, 就很有可能被迫使用这个框架. 
     */
    static func save(_ image: UIImage) -> Observable<String> {
        return Observable.create { observer in
            // 异步操作真正的开启的地方.
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success, let id = savedAssetId {
                        // 在合适的地方, 触发状态的修改.
                        observer.onNext(id)
                        observer.onCompleted()
                    } else {
                        // 在合适的地方, 触发状态改变的修改.
                        observer.onError(error ?? Errors.couldNotSavePhoto)
                    }
                }
            })
            return Disposables.create()
        }
    }
}
