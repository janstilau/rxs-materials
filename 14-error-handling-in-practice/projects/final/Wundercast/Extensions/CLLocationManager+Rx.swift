import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class RxCLLocationManagerDelegateProxy : DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    public init(locationManager: CLLocationManager) {
        super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        // 这里其实是向工厂方法里面, 增加如何进行 RxCLLocationManagerDelegateProxy 的生成.
        self.register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
    }
    
    static func currentDelegate(for object: CLLocationManager) -> CLLocationManagerDelegate? {
        let locationManager: CLLocationManager = object
        return locationManager.delegate
    }
    
    static func setCurrentDelegate(_ delegate: CLLocationManagerDelegate?, to object: CLLocationManager) {
        let locationManager: CLLocationManager = object
        locationManager.delegate = delegate
    }
}

public extension Reactive where Base: CLLocationManager {
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    var didUpdateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map { a in
                return a[1] as! [CLLocation]
            }
    }
    
}
