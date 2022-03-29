import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    // 所有的, 都集中到了一个 VC 里面.
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var mapBtn: UIButton!
    @IBOutlet private var locationBtn: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var cityNameTextField: UITextField!
    @IBOutlet private var temperatureLabel: UILabel!
    @IBOutlet private var humidityLabel: UILabel!
    @IBOutlet private var iconLabel: UILabel!
    @IBOutlet private var cityNameLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        bindSignals()
        Appearance.applyBottomLine(to: cityNameTextField)
    }
}

extension ViewController {
    
    // 做最初的 View 的配置工作.
    private func configureViews() {
        view.backgroundColor = UIColor.aztec
        cityNameTextField.attributedPlaceholder = NSAttributedString(string: "City's Name",
                                                                     attributes: [.foregroundColor: UIColor.textGrey])
        cityNameTextField.textColor = UIColor.ufoGreen
        temperatureLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
    
    // 真正的绑定部分.
    private func bindSignals() {
        
        // 当, 用户输入完 TextField 的内容之后, 会发射一个信号, 将最新的输入城市当做数据.
        let searchInputChange = cityNameTextField.rx
        // ControlEvent 用来触发信号.
            .controlEvent(.editingDidEndOnExit)
        // map 用来获取当前 TextFiled 的值. Map 也可以这样用, 上级节点的数据无关重要.
            .map { self.cityNameTextField.text ?? "" }
            .filter { !$0.isEmpty }
        
        let mapInputChange = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in
                CLLocation(latitude: self.mapView.centerCoordinate.latitude,
                           longitude: self.mapView.centerCoordinate.longitude)
            }
        
        // 定位了之后, 没有关闭定位.
        let locationInputChange = locationBtn.rx.tap
            .flatMapLatest { _ in self.locationManager.rx.getCurrentLocation() }
        
        // 不管是, 定位, 还是 MapView 的移动, 最终拿到的都是一个经纬度的值.
        // Merge 在这里进行了使用, 当两个 Publisher 使用的是同一种类型的 NextEle 的时候, 就可以 Merge, 使用统一的处理方法触发后面的逻辑.
        let geoSearch = Observable.merge(locationInputChange, mapInputChange)
        // 这里使用的是 FlatMapLatest, 所以, 会一直使用最新的信号进行后续的操作.
            .flatMapLatest { location in
                ApiController.shared
                    .currentWeather(at: location.coordinate)
                    .catchErrorJustReturn(.empty)
            }
        
        // 用户输入行为, 会触发一个网络请求 API,
        let textSearch = searchInputChange.flatMap { city in
            ApiController.shared
                .currentWeather(for: city)
            // 如果网络出错了, 返回一个默认数据.
            // 在 Rx 里面, 各个 Model 定义一个 static 变量当默认值, 很常见.
                .catchErrorJustReturn(.empty)
        }
        
        let search = Observable
            .merge(geoSearch, textSearch)
            .asDriver(onErrorJustReturn: .empty)
        
        // 前面三个, 都是用户的行为, 触发了之后, 代表着正在获取 weather 的数据.
        // 后面一个, 则是得到了 Weather 的结果.
        // 所以, 这里 map 都是写死的值.
        let running = Observable.merge(
            searchInputChange.map { _ in true },
            locationInputChange.map { _ in true },
            mapInputChange.map { _ in true },
            search.map { _ in false }.asObservable()
        )
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        // Runing 代表的含义是, 当前是否有用户操作导致的请求.
        // 这个 Runing 到底怎么触发的, 到现在已经难以跟踪的到了. 这也是 rx swift 难以调试的原因.
        // 不过, 有了这样的一个逻辑统一的信号 Publisher 点, 所有的和正在 Searing 相关的 UI 部分, 有了一个统一的设置点.
        running
            .skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
        
        running
            .drive(temperatureLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(iconLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: bag)
        
        
        search.map { "\($0.temperature)° C" }
        .drive(temperatureLabel.rx.text)
        .disposed(by: bag)
        
        // 使用 KeyPath 的方式, 进行了取值. 然后设置到 Text 的属性上了.
        search.map(\.icon)
            .drive(iconLabel.rx.text)
            .disposed(by: bag)
        
        search.map { "\($0.humidity)%" }
        .drive(humidityLabel.rx.text)
        .disposed(by: bag)
        
        search.map(\.cityName)
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)
        
        
        mapBtn.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden.toggle()
            })
            .disposed(by: bag)
        
        // mapView 中, 已经将实际的 Delegate 设置为了自己的内部类了, 在这里, 是将 self 变为 Forward Delegate
        mapView.rx
            .setDelegate(self)
            .disposed(by: bag)
        
        // 当, 有了新的数据了之后, 会直接给到 MapView, MapView 怎么设置, 不用管.
        search
            .map { $0.overlay() }
            .drive(mapView.rx.overlay)
            .disposed(by: bag)
    }
}

// 怎么变出 MKOverlayRenderer 交给了 ApiController.Weather 内部进行处理.
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? ApiController.Weather.Overlay else {
            return MKOverlayRenderer()
        }
        return ApiController.Weather.OverlayView(overlay: overlay,
                                                 overlayIcon: overlay.icon)
    }
}
