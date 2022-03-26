/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import XCTest
import Accounts

import RxSwift
import RxCocoa

@testable import Tweetie

// 实现接口的意义就在于, 我们可以轻易的 Mock 功能实现.
// 在项目初始化的时候, 就可以向 objects 里面, 进行数据的初始化工作, 使用本地数据进行 Mock.
// 一般来说, Mock 的类, 一定要有可以直接进行数据控制的接口, 使得外界可以直接Mock 数据.
// 然后, 在实现接口的时候, 直接使用这些 Mock 的数据.
class TwitterTestAPI: TwitterAPIProtocol {
  
  static func reset() {
    lastMethodCall = nil
    objects = PublishSubject<[JSONObject]>()
  }

  static var objects = PublishSubject<[JSONObject]>()
  static var lastMethodCall: String?

  static func timeline(of username: String) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]> {
    return { account, cursor in
      lastMethodCall = #function
      return objects.asObservable()
    }
  }

  static func timeline(of list: ListIdentifier) -> (AccessToken, TimelineCursor) -> Observable<[JSONObject]> {
    return { account, cursor in
      lastMethodCall = #function
      return objects.asObservable()
    }
  }

  static func members(of list: ListIdentifier) -> (AccessToken) -> Observable<[JSONObject]> {
    return { list in
      lastMethodCall = #function
      return objects.asObservable()
    }
  }
}
