import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

typealias Weather = ApiController.Weather

class ViewController: UIViewController {
    
    @IBOutlet weak var keyButton: UIButton!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    
    private var cache = [String: Weather]()
    private let bag = DisposeBag()
    private let locationManager = CLLocationManager()
    
    var keyTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        
        // 给了用户, 输入自定义 key 的入口.
        keyButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                // 要用 weak, 事件序列的中间节点, 是自引用进行了生命周期的控制.
                // 这里的另外的一条引用循环, 应该是 Bg -> block, block -> Self -> Bag
                self?.requestKey()
            })
            .disposed(by:bag)
        
        // locationChanged 这个事件序列, 是 LocationManager 的 Delegate 方法的包装, 所以是需要一个触发点的.
        // 那么这个触发点, 其实就是 geoLocationButton.rx.tap
        // mapLocationChanged 是用户按钮点击, 然后使用 do 这种方式, 增加了处理的中间流程. 这里不用 subscribe, 是因为后面还是想要使用这个事件序列.
        let locationChanged = locationManager.rx.didUpdateLocations
            .map { locations in locations[0] }
            .filter { location in
                return location.horizontalAccuracy == kCLLocationAccuracyNearestTenMeters
            }
        
        // 这里没有使用 share, 所以应该是会产生很多的 tap 监听.
        // 最 ViewDidLoad 最后, 查看 geoLocationButton 的 allTargets, 发现有两个 RxCocoa.ControlTarget 生成了.
        let mapLocationTapped = geoLocationButton.rx.tap
            .do(onNext: { [weak self] _ in
                self?.locationManager.requestWhenInUseAuthorization()
                self?.locationManager.startUpdatingLocation()
                self?.searchCityName.text = "Current Location"
            })
                // 只取第一个值.
                let geoLocationChanged = mapLocationTapped.flatMap {
                    return locationChanged.take(1)
                }
                
                // 然后触发网络请求.
                // 网络请求中添加 catchErrorJustReturn, 目的在于, 让后面的节点, 可以使用有效值.
                // 本身 ApiController.shared.currentWeather(at: location.coordinate) 这个 source 已经废弃掉了.
                // 如果不在这里进行 catchErrorJustReturn 的处理, 那么 geoSearch 就会让 error 污染后面的所有注册, 之后的节点全部变为了 dispose 的状态.
                // 所以, error 的 catch, 在这种一次性的 Obsersable 里面其实是很重要的.
                // 这也就是为什么在各个 Model 里面, 会有各种 static 对象定义的出现. 在发生错误之后, return 这个 static 对象, 这样后续的 UI 逻辑还是能够正常的执行, 不过 UI 上, 要专门对于这种对象做处理. 例如变红. 
                let geoSearch = geoLocationChanged.flatMap { location in
                    return ApiController.shared.currentWeather(at: location.coordinate)
                        .catchErrorJustReturn(.empty)
                }
                
                let maxAttempts = 4
                
                let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
                    
                    // flatMap 是, 返回值是什么样的类型, 他返回的就是什么类型.
                    return e.enumerated().flatMap { attempCount, error -> Observable<Int> in
                        
                        if attempCount >= maxAttempts - 1 {
                            // 次数太多了, 不在进行 retry.
                            // ErrorProducer(error: error), 可以保持原有的 Element 的类型.
                            return Observable.error(error)
                        } else if let casted = error as? ApiController.ApiError, casted == .invalidKey {
                            // 如果是 Api 的 key 不对. 继续????
                            // 只要是当前的 API 有值, 那么就继续尝试.
                            return ApiController.shared.apiKey
                                .filter { !$0.isEmpty }
                                .map { _ in 1 }
                        }
                        
                        // 间隔几秒之后, 再次进行.
                        // 创建一个 timer 之后, 立马进行 take(1), 就可以实现一次性 timer 的效果.
                        return Observable<Int>.timer(.seconds(attempCount + 1),
                                                     scheduler: MainScheduler.instance)
                            .take(1)
                    }
                }
                
                let searchInputChanged = searchCityName.rx.controlEvent(.editingDidEndOnExit)
                .map { [weak self] _ in self?.searchCityName.text ?? "" }
                .filter { !$0.isEmpty }
        
        let textSearch = searchInputChanged.flatMap { text in
            return ApiController.shared.currentWeather(city: text)
                .do(
                    // 使用 do, 进行了事件序列流转过程中, 中间状态的处理.
                    onNext: { [weak self] data in
                        self?.cache[text] = data
                    },
                    onError: { error in
                        // 当发生错误的时候, 直接进行了弹框 .
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.showError(error: error)
                        }
                    })
                    .retryWhen(retryHandler)
                    .catchError { [weak self] error in
                        // 当上面的错误处理 retry 失败之后, 最后的错误处理的结果.
                        return Observable.just(self?.cache[text] ?? .empty)
                    }
        }
        
        let search = Observable.merge(geoSearch, textSearch)
            .asDriver(onErrorJustReturn: .empty)
        
        let running = Observable.merge(searchInputChanged.map { _ in true },
                                       mapLocationTapped.map { _ in true },
                                       search.map { _ in false }.asObservable())
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        search.map { "\($0.temperature)° C" }
        .drive(tempLabel.rx.text)
        .disposed(by:bag)
        
        search.map(\.icon)
            .drive(iconLabel.rx.text)
            .disposed(by:bag)
        
        search.map { "\($0.humidity)%" }
        .drive(humidityLabel.rx.text)
        .disposed(by:bag)
        
        search.map(\.cityName)
            .drive(cityNameLabel.rx.text)
            .disposed(by:bag)
        
        running.skip(1).drive(activityIndicator.rx.isAnimating).disposed(by:bag)
        running.drive(tempLabel.rx.isHidden).disposed(by:bag)
        running.drive(iconLabel.rx.isHidden).disposed(by:bag)
        running.drive(humidityLabel.rx.isHidden).disposed(by:bag)
        running.drive(cityNameLabel.rx.isHidden).disposed(by:bag)
        print("The End Line")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func requestKey() {
        func configurationTextField(textField: UITextField!) {
            self.keyTextField = textField
        }
        
        let alert = UIAlertController(title: "Api Key",
                                      message: "Add the api key:",
                                      preferredStyle: UIAlertController.Style.alert)
        // 这种写法, 第一次见.
        // 在函数内定义一个函数, 然后把这个函数当做变量来用.
        // 其实之前 OC 定义 Block 的方式也能使用这种方式, 不过, 使用 func 这种方式, 更加的清晰.
        alert.addTextField(configurationHandler: configurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            // 指令式的世界, 用户点击的回调是什么
            // 就是将值存储到 apiKey 中去. 再次证明了, Subject 和成员变量的相似性.
            ApiController.shared.apiKey.onNext(self?.keyTextField?.text ?? "")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive))
        
        self.present(alert, animated: true)
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
    
    private func showError(error e: Error) {
        guard let e = e as? ApiController.ApiError else {
            InfoView.showIn(viewController: self, message: "An error occurred")
            return
        }
        
        switch e {
        case .cityNotFound:
            InfoView.showIn(viewController: self, message: "City Name is invalid")
        case .serverFailure:
            InfoView.showIn(viewController: self, message: "Server error")
        case .invalidKey:
            InfoView.showIn(viewController: self, message: "Key is invalid")
        }
    }
}
