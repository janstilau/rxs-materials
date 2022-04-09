import Foundation

public enum MainViewState {
    
    case launching
    case onboarding
    case signedIn(userSession: UserSession)
}

extension MainViewState: Equatable {
    
    public static func ==(lhs: MainViewState, rhs: MainViewState) -> Bool {
        switch (lhs, rhs) {
        case (.launching, .launching):
            return true
        case (.onboarding, .onboarding):
            return true
        case let (.signedIn(l), .signedIn(r)):
            return l == r
        case (.launching, _),
            (.onboarding, _),
            (.signedIn, _):
            return false
        }
    }
}
