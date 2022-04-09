import Foundation

// 使用 Enum, 将状态分割的清清楚楚.
public enum LoadedState<T: Equatable>: Equatable {

  case notLoaded
  case loaded(state: T)
}
