// Copyright (c) 2016 Justin Kolb - http://franticapparatus.net
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

public enum PromiseError : ErrorType {
    case CycleDetected
    case ContextUnavailable
}

private class PendingInfo<T> {
    var promiseToKeepAlive: AnyObject?
    var onFulfilled: [(T) -> Void] = []
    var onRejected: [(ErrorType) -> Void] = []
    
    private init() {
        self.promiseToKeepAlive = nil
    }

    private init<P>(waitForPromise: Promise<P>) {
        self.promiseToKeepAlive = waitForPromise
    }
    
    func waitForPromise<P>(promise: Promise<P>) {
        self.promiseToKeepAlive = promise
    }
    
    func fulfilled(value: T) {
        let handlers = onFulfilled
        dispatch_async(dispatch_get_main_queue()) {
            for handler in handlers {
                handler(value)
            }
        }
    }
    
    func rejected(reason: ErrorType) {
        let handlers = onRejected
        dispatch_async(dispatch_get_main_queue()) {
            for handler in handlers {
                handler(reason)
            }
        }
    }
}

private enum State<T> {
    case Pending(PendingInfo<T>)
    case Fulfilled(T)
    case Rejected(ErrorType)
}

public class Promise<T> {
    private var state: State<T>
    private let lock = NSLock()
    
    public init(@noescape _ resolver: (fulfill: (T) -> Void, reject: (ErrorType) -> Void, isCancelled: () -> Bool) -> Void) {
        state = .Pending(PendingInfo())
        
        let weakFulfill: (T) -> Void = { [weak self] (value) -> Void in
            guard let strongSelf = self else { return }
            Promise<T>.resolve(strongSelf)(Promise<T>(value))
        }
        
        let weakReject: (ErrorType) -> Void = { [weak self] (reason) -> Void in
            guard let strongSelf = self else { return }
            Promise<T>.resolve(strongSelf)(Promise<T>(error: reason))
        }

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        resolver(fulfill: weakFulfill, reject: weakReject, isCancelled: isCancelled)
    }
    
    public init(_ value: T) {
        state = .Fulfilled(value)
    }
    
    public init(error: ErrorType) {
        state = .Rejected(error)
    }
    
    private init<P>(waitForPromise: Promise<P>) {
        state = .Pending(PendingInfo(waitForPromise: waitForPromise))
    }
    
    private func synchronize(@noescape synchronized: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        synchronized()
    }
    
    private func resolve(promise: Promise<T>) {
        promise.synchronize {
            switch promise.state {
            case .Fulfilled(let value):
                fulfillWithValue(value)
            case .Rejected(let reason):
                rejectWithReason(reason)
            case .Pending(let info):
                waitForPromise(promise, promiseInfo: info)
            }
        }
    }
    
    private func fulfillWithValue(value: T) {
        synchronize {
            switch state {
            case .Pending(let info):
                state = .Fulfilled(value)
                info.fulfilled(value)
            default:
                fatalError("Duplicate attempt to resolve promise")
            }
        }
    }
    
    private func rejectWithReason(reason: ErrorType) {
        synchronize {
            switch state {
            case .Pending(let info):
                state = .Rejected(reason)
                info.rejected(reason)
            default:
                fatalError("Duplicate attempt to resolve promise")
            }
        }
    }
    
    private func waitForPromise(promise: Promise<T>, promiseInfo: PendingInfo<T>) {
        if promise === self {
            rejectWithReason(PromiseError.CycleDetected)
            return
        }

        synchronize {
            switch state {
            case .Pending(let info):
                promiseInfo.onFulfilled.append { [weak self] (value) -> Void in
                    guard let strongSelf = self else { return }
                    strongSelf.resolve(Promise<T>(value))
                }
                promiseInfo.onRejected.append { [weak self] (reason) -> Void in
                    guard let strongSelf = self else { return }
                    strongSelf.resolve(Promise<T>(error: reason))
                }
                info.waitForPromise(promise)
            default:
                fatalError("Attempting to wait on a promise after already being resolved")
            }
        }
    }
    
    public func then<R>(onFulfilled onFulfilled: (T) throws -> Promise<R>, onRejected: (ErrorType) throws -> Promise<R>) -> Promise<R> {
        let promise = Promise<R>(waitForPromise: self)
        
        let fulfiller: (T) -> Void = { [weak promise] (value) -> Void in
            guard let strongPromise = promise else { return }
            
            do {
                strongPromise.resolve(try onFulfilled(value))
            }
            catch {
                strongPromise.resolve(Promise<R>(error: error))
            }
        }
        
        let rejecter: (ErrorType) -> Void = { [weak promise] (reason) -> Void in
            guard let strongPromise = promise else { return }
            
            do {
                strongPromise.resolve(try onRejected(reason))
            }
            catch {
                strongPromise.resolve(Promise<R>(error: error))
            }
        }
        
        synchronize {
            switch state {
            case .Pending(let info):
                info.onFulfilled.append(fulfiller)
                info.onRejected.append(rejecter)
            case .Fulfilled(let value):
                dispatch_async(dispatch_get_main_queue()) {
                    fulfiller(value)
                }
            case .Rejected(let reason):
                dispatch_async(dispatch_get_main_queue()) {
                    rejecter(reason)
                }
            }
        }
        
        return promise
    }
    
    public func then<R>(onFulfilled onFulfilled: (T) throws -> R, onRejected: (ErrorType) throws -> R) -> Promise<R> {
        return then(
            onFulfilled: { (value) -> Promise<R> in
                return Promise<R>(try onFulfilled(value))
            },
            onRejected: { (reason) -> Promise<R> in
                return Promise<R>(try onRejected(reason))
            }
        )
    }
    
    public func then(onFulfilled: (T) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                try onFulfilled(value)
                return value
            },
            onRejected: { (reason) -> T in
                throw reason
            }
        )
    }
    
    public func thenWithContext<C: AnyObject>(context: C, _ onFulfilled: (C, T) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] (value) -> T in
                if let strongContext = context {
                    try onFulfilled(strongContext, value)
                }
                
                return value
            },
            onRejected: { (reason) -> T in
                throw reason
            }
        )
    }
    
    public func then<R>(onFulfilled: (T) throws -> R) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { (reason) -> R in
                throw reason
            }
        )
    }
    
    public func then<R>(onFulfilled: (T) throws -> Promise<R>) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { (reason) -> Promise<R> in
                throw reason
            }
        )
    }
    
    public func thenWithContext<C: AnyObject, R>(context: C, _ onFulfilled: (C, T) throws -> R) -> Promise<R> {
        return then(
            onFulfilled: { [weak context] (value) -> R in
                if let strongContext = context {
                    return try onFulfilled(strongContext, value)
                } else {
                    throw PromiseError.ContextUnavailable
                }
            },
            onRejected: { (reason) -> R in
                throw reason
            }
        )
    }
    
    public func thenWithContext<C: AnyObject, R>(context: C, _ onFulfilled: (C, T) throws -> Promise<R>) -> Promise<R> {
        return then(
            onFulfilled: { [weak context] (value) -> Promise<R> in
                if let strongContext = context {
                    return try onFulfilled(strongContext, value)
                } else {
                    throw PromiseError.ContextUnavailable
                }
            },
            onRejected: { (reason) -> Promise<R> in
                throw reason
            }
        )
    }
    
    public func handle(onRejected: (ErrorType) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                return value
            },
            onRejected: { (reason) -> T in
                try onRejected(reason)
                
                throw reason
            }
        )
    }
    
    public func handleWithContext<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                return value
            },
            onRejected: { [weak context] (reason) -> T in
                if let strongContext = context {
                    try onRejected(strongContext, reason)
                }
                
                throw reason
            }
        )
    }
    
    public func recover(onRejected: (ErrorType) throws -> T) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                return value
            },
            onRejected: onRejected
        )
    }
    
    public func recover(onRejected: (ErrorType) throws -> Promise<T>) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> Promise<T> in
                return Promise<T>(value)
            },
            onRejected: onRejected
        )
    }

    public func recoverWithContext<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) throws -> T) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                return value
            },
            onRejected: { [weak context] (reason) -> T in
                if let strongContext = context {
                    return try onRejected(strongContext, reason)
                } else {
                    throw PromiseError.ContextUnavailable
                }
            }
        )
    }
    
    public func recoverWithContext<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) throws -> Promise<T>) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> Promise<T> in
                return Promise<T>(value)
            },
            onRejected: { [weak context] (reason) -> Promise<T> in
                if let strongContext = context {
                    return try onRejected(strongContext, reason)
                } else {
                    throw PromiseError.ContextUnavailable
                }
            }
        )
    }
    
    public func finally(onFinally: () -> Void) -> Promise<T> {
        return then(
            onFulfilled: { (value) -> T in
                onFinally()
                return value
            },
            onRejected: { (reason) -> T in
                onFinally()
                throw reason
            }
        )
    }
    
    public func finallyWithContext<C: AnyObject>(context: C, _ onFinally: (C) -> Void) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] (value) -> T in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                
                return value
            },
            onRejected: { [weak context] (reason) -> T in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                
                throw reason
            }
        )
    }
}
