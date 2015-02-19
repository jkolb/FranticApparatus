//
// Promise.swift
// FranticApparatus
//
// Copyright (c) 2014-2015 Justin Kolb - http://franticapparatus.net
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

enum State {
    case Pending
    case Fulfilled
    case Rejected
}

public enum Result<T> {
    case Success(Value<T>)
    case Deferred(Promise<T>)
    case Failure(Error)
    
    public init(_ value: T) {
        self = Success(Value(value))
    }
    
    public init(_ promise: Promise<T>) {
        self = Deferred(promise)
    }
    
    public init(_ reason: Error) {
        self = Failure(reason)
    }
}

public class Promise<T> : Synchronizable {
    public let synchronizationQueue: DispatchQueue
    private var state: State = .Pending
    private var result: Result<T>? = nil
    private let parent: (() -> Any)?
    private var onFulfilled = Array<(T) -> ()>()
    private var onRejected = Array<(Error) -> ()>()
    
    public init(_ resolver: (fulfill: (T) -> (), reject: (Error) -> (), isCancelled: () -> Bool) -> ()) {
        self.parent = nil
        self.synchronizationQueue = GCDQueue.serial("net.franticapparatus.Promise")
        
        let weakFulfill: (T) -> () = { [weak self] (value) -> () in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(Result(value))
            }
        }
        
        let weakReject: (Error) -> () = { [weak self] (reason) -> () in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(Result(reason))
            }
        }

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        resolver(fulfill: weakFulfill, reject: weakReject, isCancelled: isCancelled)
    }
    
    private init(parent: (() -> Any), synchronizationQueue: DispatchQueue, resolver: ((Result<T>) -> ()) -> ()) {
        self.parent = parent
        self.synchronizationQueue = synchronizationQueue
        
        let weakResolve: (Result<T>) -> () = { [weak self] (result) -> () in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(result)
            }
        }
        
        resolver(weakResolve)
    }
    
    private func resolve(result: Result<T>) {
        synchronizeWrite(self) { (promise) -> () in
            promise.transition(result)
        }
    }
    
    private func transition(result: Result<T>) {
        switch state {
        case .Pending:
            switch result {
            case .Success(let value):
                self.result = result
                state = .Fulfilled
                for fulfillHandler in onFulfilled {
                    fulfillHandler(value.unwrap)
                }
                onFulfilled.removeAll(keepCapacity: false)
                onRejected.removeAll(keepCapacity: false)
            case .Failure(let reason):
                self.result = result
                state = .Rejected
                for rejectHandler in onRejected {
                    rejectHandler(reason)
                }
                onFulfilled.removeAll(keepCapacity: false)
                onRejected.removeAll(keepCapacity: false)
            case .Deferred(let promise):
                assert(promise !== self, "A promise referencing itself causes an unbreakable retain cycle, and an infinite loop")
                self.result = Result(promise.thenOn(
                    synchronizationQueue,
                    onFulfilled: { [weak self] (value: T) -> Result<T> in
                        let result: Result<T> = Result(value)
                        if let strongSelf = self {
                            strongSelf.transition(result)
                        }
                        return result
                    },
                    onRejected: { [weak self] (reason: Error) -> Result<T> in
                        let result: Result<T> = Result(reason)
                        if let strongSelf = self {
                            strongSelf.transition(result)
                        }
                        return result
                    }
                ))
                state = .Pending
            }
        default:
            return
        }
    }
    
    public func then<R>(# onFulfilled: (T) -> Result<R>, onRejected: (Error) -> Result<R>) -> Promise<R> {
        return thenOn(GCDQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    public func thenOn<R>(thenQueue: DispatchQueue, onFulfilled: (T) -> Result<R>, onRejected: (Error) -> Result<R>) -> Promise<R> {
        return Promise<R>(parent: {self}, synchronizationQueue: synchronizationQueue) { (resolve) -> () in
            let fulfiller: (T) -> () = { (value) -> () in
                thenQueue.dispatch {
                    let result = onFulfilled(value)
                    resolve(result)
                }
            }
            let rejecter: (Error) -> () = { (reason) -> () in
                thenQueue.dispatch {
                    let result = onRejected(reason)
                    resolve(result)
                }
            }
            
            synchronizeWrite(self) { (parent) in
                switch parent.state {
                case .Pending:
                    parent.onFulfilled.append(fulfiller)
                    parent.onRejected.append(rejecter)
                default:
                    if let result = parent.result {
                        switch result {
                        case .Success(let value):
                            fulfiller(value.unwrap)
                        case .Failure(let reason):
                            rejecter(reason)
                        default:
                            fatalError("Promise must have a success or failure result when not pending")
                        }
                    } else {
                        fatalError("Promise is required to have a result when not pending")
                    }
                }
            }
        }
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
    
    public func when<C: AnyObject>(context: C, _ onFulfilled: (C, T) -> ()) -> Promise<T> {
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
    
    public func when<C: AnyObject, R>(context: C, _ onFulfilled: (C, T) -> Result<R>) -> Promise<R> {
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
    
    public func catch<C: AnyObject>(context: C, _ onRejected: (C, Error) -> ()) -> Promise<T> {
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
    
    public func recover<C: AnyObject>(context: C, _ onRejected: (C, Error) -> Result<T>) -> Promise<T> {
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
    
    public func finally<C: AnyObject>(context: C, _ onFinally: (C) -> ()) -> Promise<T> {
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
