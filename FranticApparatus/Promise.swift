//
// Promise.swift
// FranticApparatus
//
// Copyright (c) 2014 Justin Kolb - http://franticapparatus.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

enum State<T> {
    case Pending
    case Fulfilled(@autoclosure () -> T)
    case Rejected(Error)
}

enum Result<T> {
    case Success(@autoclosure () -> T)
    case Deferred(Promise<T>)
    case Failure(Error)
}

class Error {
    let message: String
    
    init(message: String = "") {
        self.message = message
    }
}

class Promise<T> {
    let synchronizationQueue: SerialTaskQueue
    let parent: (() -> Any)?
    var currentState: State<T> = .Pending
    var deferred: Promise<T>! = nil
    var onFulfilled = Array<(T) -> ()>()
    var onRejected = Array<(Error) -> ()>()
    
    init(synchronizationQueue: SerialTaskQueue = GCDSerialTaskQueue(), parent: (() -> Any)? = nil) {
        self.synchronizationQueue = synchronizationQueue
        self.parent = parent
    }
    
    func fulfill(value: T) {
        synchronize { (synchronizedPromise) -> () in
            synchronizedPromise.state = .Fulfilled(value)
        }
    }
    
    func reject(reason: Error) {
        synchronize { (synchronizedPromise) -> () in
            synchronizedPromise.state = .Rejected(reason)
        }
    }
    
    var state: State<T> {
        get {
            return currentState
        }
        set {
            switch currentState {
            case .Pending:
                switch newValue {
                case .Fulfilled(let value):
                    currentState = newValue
                    for fulfillHandler in onFulfilled {
                        fulfillHandler(value())
                    }
                case .Rejected(let reason):
                    currentState = newValue
                    for rejectHandler in onRejected {
                        rejectHandler(reason)
                    }
                case .Pending:
                    fatalError("Attempting to transition from Pending to Pending")
                }
                onFulfilled.removeAll(keepCapacity: false)
                onRejected.removeAll(keepCapacity: false)
            default:
                return
            }
        }
    }
    
    func resolve(result: Result<T>) {
        synchronize { (synchronizedPromise) -> () in
            switch result {
            case .Success(let value):
                synchronizedPromise.state = .Fulfilled(value())
            case .Failure(let reason):
                synchronizedPromise.state = .Rejected(reason)
            case .Deferred(let deferred):
                switch deferred.state {
                case .Pending:
                    assert(synchronizedPromise !== deferred, "A promise referencing itself causes an unbreakable retain cycle")
                    assert(synchronizedPromise.deferred == nil, "Attempt to reassign deferred")
                    synchronizedPromise.deferred = deferred.thenOn(
                        synchronizedPromise.synchronizationQueue,
                        onFulfilled: { [weak synchronizedPromise] (value: T) -> Result<T> in
                            synchronizedPromise?.state = .Fulfilled(value)
                            return .Success(value)
                        },
                        onRejected: { [weak synchronizedPromise] (reason: Error) -> Result<T> in
                            synchronizedPromise?.state = .Rejected(reason)
                            return .Failure(reason)
                        }
                    )
                default:
                    synchronizedPromise.state = deferred.state
                }
            }
        }
    }

    func synchronize(task: (Promise<T>) -> ()) {
        synchronizeOn(synchronizationQueue, task: task)
    }
    
    func synchronizeOn(queue: SerialTaskQueue, task: (Promise<T>) -> ()) {
        queue.dispatch { [weak self] in
            if let blockSelf = self {
                task(blockSelf)
            }
        }
    }
    
    func callbackHandler<V>(callbackQueue: SerialTaskQueue, callback: ((V) -> Result<T>)) -> (V) -> () {
        return { [weak self] (value: V) -> () in
            if let promise = self {
                promise.synchronizeOn(callbackQueue) { (synchronizedPromise) -> () in
                    let result = callback(value)
                    synchronizedPromise.resolve(result)
                }
            }
        }
    }
    
    func then<R>(# onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        return thenOn(GCDSerialTaskQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }

    func thenOn<R>(thenQueue: SerialTaskQueue, onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        var child = Promise<R>(synchronizationQueue: synchronizationQueue, parent: {self})
        let fulfillChild = child.callbackHandler(thenQueue, callback: onFulfilled)
        let rejectChild = child.callbackHandler(thenQueue, callback: onRejected)
        
        synchronize { (synchronizedPromise) -> () in
            switch synchronizedPromise.state {
            case .Pending:
                synchronizedPromise.onFulfilled.append(fulfillChild);
                synchronizedPromise.onRejected.append(rejectChild);
            case .Fulfilled(let value):
                fulfillChild(value())
            case .Rejected(let reason):
                rejectChild(reason)
            }
        }
        
        return child
    }
    
    func when(onFulfilled: ((T) -> ())) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                onFulfilled(value)
                return .Success(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                return .Failure(reason)
            }
        )
    }
    
    func when<R>(onFulfilled: ((T) -> Result<R>)) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { (reason: Error) -> Result<R> in
                return .Failure(reason)
            }
        )
    }
    
    func catch(onRejected: (Error) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                return .Success(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                onRejected(reason)
                return .Failure(reason)
            }
        )
    }
    
    func finally(onFinally: () -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                onFinally()
                return .Success(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                onFinally()
                return .Failure(reason)
            }
        )
    }
}
