import RxSwift
import Foundation
import UIKit
import Photos

class PhotoWriter {
    enum Errors: Error {
        case couldNotSavePhoto
    }
    
    // Observable.create 提供了一种, 统一的方式, 将原本的命令式逻辑, 封装成为 Observable 的逻辑.
    /*
     它的实现是, 使用一个 Sink, 当做真正的状态更改的节点. 就是传入的 observer 对象.
     create 传入的闭包内, 在合适的时机, 真正的触发状态改变的 on 方法.
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
                        observer.onError(error ?? Errors.couldNotSavePhoto)
                    }
                }
            })
            return Disposables.create()
        }
    }
}
