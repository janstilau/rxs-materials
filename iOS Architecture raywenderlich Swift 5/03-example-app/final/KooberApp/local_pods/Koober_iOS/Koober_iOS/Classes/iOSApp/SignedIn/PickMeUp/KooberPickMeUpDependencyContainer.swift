import UIKit
import KooberUIKit
import KooberKit

/*
 应该明白, Repository 里面, 不同层级的意义.
 Repository 是业务相关的, 它封装的, 是这个业务相关的存储相关的操作.
 而下面的各个文件是具体的实现. 文件存储, 网络请求, 这都是 Repository 的工具对象 .
 这些工具对象, 被 Repository 使用, 来完成各个 Repository 的接口的实现.
 
 传入给 Repository 不同的工具对象, Repository 就可以有不同的实现逻辑.
 
 */

public class KooberPickMeUpDependencyContainer {
    
    // MARK: - Properties
    
    // From parent container
    let imageCache: ImageCache
    let signedInViewModel: SignedInViewModel
    
    // Context
    let pickupLocation: Location
    
    // Long-lived dependencies
    let mapViewModel: PickMeUpMapViewModel
    let newRideRemoteAPI: NewRideRemoteAPI
    let newRideRepository: NewRideRepository
    let rideOptionDataStore: RideOptionDataStore
    let pickMeUpViewModel: PickMeUpViewModel
    
    // MARK: - Methods
    init(signedInDependencyContainer: KooberSignedInDependencyContainer,
         pickupLocation: Location) {
        func makePickMeUpMapViewModel() -> PickMeUpMapViewModel {
            return PickMeUpMapViewModel(pickupLocation: pickupLocation)
        }
        func makeNewRideRemoteAPI() -> NewRideRemoteAPI {
            return FakeNewRideRemoteAPI()
        }
        func makeNewRideRepository(newRideRemoteAPI: NewRideRemoteAPI) -> NewRideRepository {
            let newRideRemoteAPI = makeNewRideRemoteAPI()
            return KooberNewRideRepository(remoteAPI: newRideRemoteAPI)
        }
        func makeRideOptionDataStore() -> RideOptionDataStore {
            return RideOptionDataStoreInMemory()
        }
        func makePickMeUpViewModel(newRideRepository: NewRideRepository,
                                   newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder,
                                   mapViewModel: PickMeUpMapViewModel) -> PickMeUpViewModel {
            return PickMeUpViewModel(pickupLocation: pickupLocation,
                                     newRideRepository: newRideRepository,
                                     newRideRequestAcceptedResponder: newRideRequestAcceptedResponder,
                                     mapViewModel: mapViewModel)
        }
        
        self.imageCache = signedInDependencyContainer.imageCache
        self.signedInViewModel = signedInDependencyContainer.signedInViewModel
        
        self.pickupLocation = pickupLocation
        
        self.mapViewModel = makePickMeUpMapViewModel()
        self.newRideRemoteAPI = makeNewRideRemoteAPI()
        self.newRideRepository = makeNewRideRepository(newRideRemoteAPI: self.newRideRemoteAPI)
        self.rideOptionDataStore = makeRideOptionDataStore()
        self.pickMeUpViewModel = makePickMeUpViewModel(newRideRepository: newRideRepository,
                                                       newRideRequestAcceptedResponder: signedInViewModel,
                                                       mapViewModel: mapViewModel)
    }
    
    // Pick-me-up (container view controller)
    public func makePickMeUpViewController() -> PickMeUpViewController {
        let mapViewController = makePickMeUpMapViewController()
        let rideOptionPickerViewController = makeRideOptionPickerViewController()
        let sendingRideRequestViewController = makeSendingRideRequestViewController()
        return PickMeUpViewController(viewModel: pickMeUpViewModel,
                                      mapViewController: mapViewController,
                                      rideOptionPickerViewController: rideOptionPickerViewController,
                                      sendingRideRequestViewController: sendingRideRequestViewController,
                                      viewControllerFactory: self)
    }
    
    // Map
    func makePickMeUpMapViewController() -> PickMeUpMapViewController {
        return PickMeUpMapViewController(viewModelFactory: self,
                                         imageCache: imageCache)
    }
    
    public func makePickMeUpMapViewModel() -> PickMeUpMapViewModel {
        return mapViewModel
    }
    
    // Dropoff location picker
    public func makeDropoffLocationPickerViewController() -> DropoffLocationPickerViewController {
        let contentViewController = makeDropoffLocationPickerContentViewController()
        return DropoffLocationPickerViewController(contentViewController: contentViewController)
    }
    
    func makeDropoffLocationPickerContentViewController() -> DropoffLocationPickerContentViewController {
        return DropoffLocationPickerContentViewController(pickupLocation: pickupLocation,
                                                          viewModel: makeDropoffLocationPickerViewModel())
    }
    
    public func makeDropoffLocationPickerViewModel() -> DropoffLocationPickerViewModel {
        let repository = makeLocationRepository()
        return DropoffLocationPickerViewModel(pickupLocation: pickupLocation,
                                              locationRepository: repository,
                                              dropoffLocationDeterminedResponder: pickMeUpViewModel,
                                              cancelDropoffLocationSelectionResponder: pickMeUpViewModel)
    }
    
    public func makeLocationRepository() -> LocationRepository {
        return KooberLocationRepository(remoteAPI: newRideRemoteAPI)
    }
    
    // Ride-option picker
    public func makeRideOptionPickerViewController() -> RideOptionPickerViewController {
        return RideOptionPickerViewController(pickupLocation: pickupLocation,
                                              imageCache: imageCache,
                                              viewModelFactory: self)
    }
    
    public func makeRideOptionPickerViewModel() -> RideOptionPickerViewModel {
        let repository = makeRideOptionRepository()
        return RideOptionPickerViewModel(repository: repository,
                                         rideOptionDeterminedResponder: pickMeUpViewModel)
    }
    
    public func makeRideOptionRepository() -> RideOptionRepository {
        return KooberRideOptionRepository(remoteAPI: newRideRemoteAPI,
                                          datastore: rideOptionDataStore)
    }
    
    // Sending ride request
    public func makeSendingRideRequestViewController() -> SendingRideRequestViewController {
        return SendingRideRequestViewController()
    }
}

extension KooberPickMeUpDependencyContainer: PickMeUpViewControllerFactory {}

extension KooberPickMeUpDependencyContainer: PickMeUpMapViewModelFactory {}

extension KooberPickMeUpDependencyContainer: DropoffLocationViewModelFactory, RideOptionPickerViewModelFactory {}
