/// Copyright (c) 2018 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import ReSwift
import PromiseKit

public class ReduxSignInUserInteractions: SignInUserInteractions {

  // MARK: - Properties
  let actionDispatcher: ActionDispatcher
  let remoteAPI: AuthRemoteAPI

  // MARK: - Methods
  public init(actionDispatcher: ActionDispatcher,
              remoteAPI: AuthRemoteAPI) {
    self.actionDispatcher = actionDispatcher
    self.remoteAPI = remoteAPI
  }

  public func signIn(email: String, password: Secret) {
    indicateSigningIn()
    remoteAPI.signIn(username: email, password: password)
      .done(signedIn(to:))
      .catch(indicateErrorSigningIn)

  }

  private func indicateSigningIn() {
    let action = SignInActions.SigningIn()
    actionDispatcher.dispatch(action)
  }

  private func signedIn(to userSession: UserSession) {
    let action = SignInActions.SignedIn(userSession: userSession)
    actionDispatcher.dispatch(action)
  }

  private func indicateErrorSigningIn(error: Error) {
    let errorMessage = ErrorMessage(title: "Sign In Failed",
                                    message: "Could not sign in.\nPlease try again.")
    let action = SignInActions.SignInFailed(errorMessage: errorMessage)
    actionDispatcher.dispatch(action)
  }

  public func finishedPresenting(_ errorMessage: ErrorMessage) {
    let action = SignInActions.FinishedPresentingError(errorMessage: errorMessage)
    actionDispatcher.dispatch(action)
  }
}
