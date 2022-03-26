import Foundation
import RxSwift

print("\n\n\n===== Schedulers =====\n")

let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
let bag = DisposeBag()
let animal = BehaviorSubject(value: "[dog]")

animal
// subscribeOn 的作用, 其实是将 Publisher 的 Subscribe 方法, 在特定的 schedule 上进行触发 subscribe 的操作.
    .subscribeOn(MainScheduler.instance)
// dump 就是使用 do 进行进行后续的操作.
    .dump()
// observeOn 则是 on 事件处理应该在哪里进行进行.
    .observeOn(globalScheduler)
// dumpingSubscription 是触发整个事件序列的开始 .
    .dumpingSubscription()
    .disposed(by: bag)

let fruit = Observable<String>.create { observer in
    observer.onNext("[apple]")
    sleep(2)
    observer.onNext("[pineapple]")
    sleep(2)
    observer.onNext("[strawberry]")
    return Disposables.create()
}

fruit
    .subscribeOn(globalScheduler)
    .dump()
    .observeOn(MainScheduler.instance)
    .dumpingSubscription()
    .disposed(by: bag)

// 和 OC 的 target action 模式相比, 这种直接使用命令对象开启一个线程其实要好的多.
// 首先不用考虑内存问题, 使用闭包, 自动有着内存管理.
// 再者, 逻辑也更加的清晰, 之前还要专门定义一个类, 这个类里面的一个启动方法. 这些都是要暴露出去的, 现在直接使用一个闭包就可以了, 而闭包是可以随意进行传递的. 可以在 Thread 初始化的时候, 进行设定.
let animalsThread = Thread() {
    sleep(3)
    animal.onNext("[cat]")
    sleep(3)
    animal.onNext("[tiger]")
    sleep(3)
    animal.onNext("[fox]")
    sleep(3)
    animal.onNext("[leopard]")
}

animalsThread.name = "Animals Thread"
animalsThread.start()

animal.subscribeOn(MainScheduler.instance)
    .dump()
    .observeOn(globalScheduler)
    .dumpingSubscription()
    .disposed(by:bag)

fruit.subscribeOn(globalScheduler)
    .dump()
    .observeOn(MainScheduler.instance)
    .dumpingSubscription()
    .disposed(by:bag)

RunLoop.main.run(until: Date(timeIntervalSinceNow: 20))

/*
 
 ===== Schedulers =====

 00s | [E] [dog] emitted on Main Thread
 00s | [S] [dog] received on Anonymous Thread
 00s | [E] [dog] emitted on Main Thread
 00s | [E] [apple] emitted on Anonymous Thread
 00s | [S] [dog] received on Anonymous Thread
 
 00s | [E] [apple] emitted on Anonymous Thread
 00s | [S] [apple] received on Main Thread
 00s | [S] [apple] received on Main Thread
 02s | [E] [pineapple] emitted on Anonymous Thread
 02s | [E] [pineapple] emitted on Anonymous Thread
 02s | [S] [pineapple] received on Main Thread
 02s | [S] [pineapple] received on Main Thread
 03s | [E] [cat] emitted on Animals Thread
 03s | [S] [cat] received on Anonymous Thread
 03s | [E] [cat] emitted on Animals Thread
 03s | [S] [cat] received on Anonymous Thread
 04s | [E] [strawberry] emitted on Anonymous Thread
 04s | [E] [strawberry] emitted on Anonymous Thread
 04s | [S] [strawberry] received on Main Thread
 04s | [S] [strawberry] received on Main Thread
 06s | [E] [tiger] emitted on Animals Thread
 06s | [E] [tiger] emitted on Animals Thread
 06s | [S] [tiger] received on Anonymous Thread
 06s | [S] [tiger] received on Anonymous Thread
 09s | [E] [fox] emitted on Animals Thread
 09s | [E] [fox] emitted on Animals Thread
 09s | [S] [fox] received on Anonymous Thread
 09s | [S] [fox] received on Anonymous Thread
 12s | [E] [leopard] emitted on Animals Thread
 12s | [E] [leopard] emitted on Animals Thread
 12s | [S] [leopard] received on Anonymous Thread
 12s | [S] [leopard] received on Anonymous Thread
 */
