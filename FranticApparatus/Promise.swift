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

public enum State<T> {
    case Pending
    case Fulfilled(@autoclosure () -> T)
    case Rejected(Error)
}

public enum Result<T> {
    case Success(@autoclosure () -> T)
    case Deferred(Promise<T>)
    case Failure(Error)
}

public class Promise<T>: Synchronizable {
    public let synchronizationQueue: DispatchQueue
    let parent: (() -> Any)?
    var currentState: State<T> = .Pending
    var deferred: Promise<T>! = nil
    var onFulfilled = Array<(T) -> ()>()
    var onRejected = Array<(Error) -> ()>()
    
    public init(synchronizationQueue: DispatchQueue = GCDQueue.serial("net.franticapparatus.Promise"), parent: (() -> Any)? = nil) {
        self.synchronizationQueue = synchronizationQueue
        self.parent = parent
    }
    
    public func fulfill(value: T) {
        synchronizeWrite(self) { (promise) -> () in
            promise.state = .Fulfilled(value)
        }
    }
    
    public func reject(reason: Error) {
        synchronizeWrite(self) { (promise) -> () in
            promise.state = .Rejected(reason)
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
        synchronizeWrite(self) { (promise) -> () in
            switch result {
            case .Success(let value):
                promise.state = .Fulfilled(value())
            case .Failure(let reason):
                promise.state = .Rejected(reason)
            case .Deferred(let deferred):
                switch deferred.state {
                case .Pending:
                    // This section still feels awkward and inefficient
                    assert(promise !== deferred, "A promise referencing itself causes an unbreakable retain cycle")
                    assert(promise.deferred == nil, "Attempt to reassign deferred")
                    promise.deferred = deferred.then(
                        onFulfilled: { [weak promise] (value: T) -> Result<T> in
                            promise?.fulfill(value)
                            return .Success(value)
                        },
                        onRejected: { [weak promise] (reason: Error) -> Result<T> in
                            promise?.reject(reason)
                            return .Failure(reason)
                        }
                    )
                default:
                    promise.state = deferred.state
                }
            }
        }
    }
    
    public func then<R>(# onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        return thenOn(GCDQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    public func thenOn<R>(thenQueue: DispatchQueue, onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        var promise = Promise<R>(synchronizationQueue: synchronizationQueue, parent: {self})
        let fulfiller: (T) -> () = defer(promise, on: thenQueue) { (deferredPromise, value) -> () in
            let result = onFulfilled(value)
            deferredPromise.resolve(result)
        }
        let rejecter: (Error) -> () = defer(promise, on: thenQueue) { (deferredPromise, value) -> () in
            let result = onRejected(value)
            deferredPromise.resolve(result)
        }
        
        synchronizeWrite(self) { (promise) -> () in
            switch promise.state {
            case .Pending:
                promise.onFulfilled.append(fulfiller);
                promise.onRejected.append(rejecter);
            case .Fulfilled(let value):
                fulfiller(value())
            case .Rejected(let reason):
                rejecter(reason)
            }
        }
        
        return promise
    }
    
    public func when(onFulfilled: ((T) -> ())) -> Promise<T> {
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
    
    public func when<R>(onFulfilled: ((T) -> Result<R>)) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { (reason: Error) -> Result<R> in
                return .Failure(reason)
            }
        )
    }
    
    public func catch(onRejected: (Error) -> ()) -> Promise<T> {
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
    
    public func finally(onFinally: () -> ()) -> Promise<T> {
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
