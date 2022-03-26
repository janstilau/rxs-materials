import Foundation
import RxSwift

let start = Date()

private func getThreadName() -> String {
    if Thread.current.isMainThread {
        return "Main Thread"
    } else if let name = Thread.current.name {
        if name == "" {
            return "Anonymous Thread"
        }
        return name
    } else {
        return "Unknown Thread"
    }
}

private func secondsElapsed() -> String {
    return String(format: "%02i", Int(Date().timeIntervalSince(start).rounded()))
}

extension ObservableType {
    
    // 通过 do Operation, 添加一个新的响应节点, 在过程中, 可以对之前节点发出的数据进行处理.
    // 然后把之前的节点数据, 原封不动的送到后续节点.
    // 所以, do 其实是一个自由度很大的 Operator, 使用它可以随意的添加命令式的操作, 添加其中. 
    func dump() -> Observable<Element> {
        return self.do(onNext: { element in
            let threadName = getThreadName()
            print("\(secondsElapsed())s | [E] \(element) emitted on \(threadName)")
        })
    }
     
    // 最后的异步, 是使用 subscribe 使得整个事件序列有一个流转的结束.
    // 同时, 这其实是触发事件序列开始的起点.
    func dumpingSubscription() -> Disposable {
        return self.subscribe(
            onNext: { element in
            let threadName = getThreadName()
            print("\(secondsElapsed())s | [S] \(element) received on \(threadName)")
        })
    }
}
