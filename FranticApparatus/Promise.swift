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

public class Value<T> {
    public let unwrap: T
    
    public init(_ value: T) {
        self.unwrap = value
    }
}

enum State<T> {
    case Pending
    case Fulfilled(Value<T>)
    case Rejected(Error)
}

public enum Result<T> {
    case Success(Value<T>)
    case Deferred(Promise<T>)
    case Failure(Error)
    
    init(_ value: T) {
        self = Success(Value(value))
    }
    
    init(_ promise: Promise<T>) {
        self = Deferred(promise)
    }
    
    init(_ reason: Error) {
        self = Failure(reason)
    }
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
            promise.state = .Fulfilled(Value(value))
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
                        fulfillHandler(value.unwrap)
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
                promise.state = .Fulfilled(value)
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
                            return Result(value)
                        },
                        onRejected: { [weak promise] (reason: Error) -> Result<T> in
                            promise?.reject(reason)
                            return Result(reason)
                        }
                    )
                default:
                    promise.state = deferred.state
                }
            }
        }
    }
    
    public func then<R>(# onFulfilled: (T) -> Result<R>, onRejected: (Error) -> Result<R>) -> Promise<R> {
        return thenOn(GCDQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    public func thenOn<R>(thenQueue: DispatchQueue, onFulfilled: (T) -> Result<R>, onRejected: (Error) -> Result<R>) -> Promise<R> {
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
                promise.onFulfilled.append(fulfiller)
                promise.onRejected.append(rejecter)
            case .Fulfilled(let value):
                fulfiller(value.unwrap)
            case .Rejected(let reason):
                rejecter(reason)
            }
        }
        
        return promise
    }
    
    public func when(onFulfilled: (T) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                onFulfilled(value)
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                return Result(reason)
            }
        )
    }
    
    public func when<C: AnyObject>(context: C, onFulfilled: (C, T) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] (value: T) -> Result<T> in
                if let strongContext = context {
                    onFulfilled(strongContext, value)
                }
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                return Result(reason)
            }
        )
    }
    
    public func when<R>(onFulfilled: ((T) -> Result<R>)) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { (reason: Error) -> Result<R> in
                return Result(reason)
            }
        )
    }
    
    public func when<C: AnyObject, R>(context: C, onFulfilled: (C, T) -> Result<R>) -> Promise<R> {
        return then(
            onFulfilled: { [weak context] (value: T) -> Result<R> in
                if let strongContext = context {
                    return onFulfilled(strongContext, value)
                } else {
                    return Result(ContextUnavailableError())
                }
            },
            onRejected: { (reason: Error) -> Result<R> in
                return Result(reason)
            }
        )
    }
    
    public func catch(onRejected: (Error) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                onRejected(reason)
                return Result(reason)
            }
        )
    }
    
    public func catch<C: AnyObject>(context: C, onRejected: (C, Error) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                return Result(value)
            },
            onRejected: { [weak context] (reason: Error) -> Result<T> in
                if let strongContext = context {
                    onRejected(strongContext, reason)
                }
                return Result(reason)
            }
        )
    }
    
    public func recover(onRejected: (Error) -> Result<T>) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                return Result(value)
            },
            onRejected: onRejected
        )
    }
    
    public func recover<C: AnyObject>(context: C, onRejected: (C, Error) -> Result<T>) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                return Result(value)
            },
            onRejected: { [weak context] (error: Error) -> Result<T> in
                if let strongContext = context {
                    return onRejected(strongContext, error)
                } else {
                    return Result(error)
                }
            }
        )
    }
    
    public func finally(onFinally: () -> ()) -> Promise<T> {
        return then(
            onFulfilled: { (value: T) -> Result<T> in
                onFinally()
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<T> in
                onFinally()
                return Result(reason)
            }
        )
    }
    
    public func finally<C: AnyObject>(context: C, onFinally: (C) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] (value: T) -> Result<T> in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                return Result(value)
            },
            onRejected: { [weak context] (reason: Error) -> Result<T> in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                return Result(reason)
            }
        )
    }
}
