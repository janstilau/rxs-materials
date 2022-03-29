import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
  
  // 使用 Observable.create, 将传统的命令式的操作, 变为了 Observable 事件序列.
  static var authorized: Observable<Bool> {
    
    return Observable.create { observer in
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.onNext(true)
          observer.onCompleted()
        } else {
          observer.onNext(false)
          requestAuthorization { newStatus in
            observer.onNext(newStatus == .authorized)
            observer.onCompleted()
          }
        }
      }
      return Disposables.create()
    }
  }
}
