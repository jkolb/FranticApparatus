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
    private var parent: (() -> Any)?
    var deferred: Promise<T>? = nil
    var onFulfilled: [(T) -> Void] = []
    var onRejected: [(ErrorType) -> Void] = []
    
    private init() {
        self.parent = nil
    }

    private init(parent: () -> Any) {
        self.parent = parent
    }
    
    func clearParent() {
        parent = nil
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
        
        let weakFulfill: (T) -> Void = { [weak self] value in
            guard let strongSelf = self else { return }
            Promise<T>.resolve(strongSelf)(Promise<T>(fulfill: value))
        }
        
        let weakReject: (ErrorType) -> Void = { [weak self] reason in
            guard let strongSelf = self else { return }
            Promise<T>.resolve(strongSelf)(Promise<T>(reject: reason))
        }

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        resolver(fulfill: weakFulfill, reject: weakReject, isCancelled: isCancelled)
    }
    
    public init(fulfill: T) {
        state = .Fulfilled(fulfill)
    }
    
    public init(reject: ErrorType) {
        state = .Rejected(reject)
    }
    
    private init(parent: () -> Any, @noescape resolver: ((Promise<T>) -> Void) -> Void) {
        state = .Pending(PendingInfo(parent: parent))
        
        let weakResolve: (Promise<T>) -> Void = { [weak self] promise in
            guard let strongSelf = self else { return }
            Promise<T>.resolve(strongSelf)(promise)
        }
        
        resolver(weakResolve)
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
            case .Pending:
                waitForPromise(promise)
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
                return
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
                return
            }
        }
    }
    
    private func waitForPromise(promise: Promise<T>) {
        if promise === self {
            rejectWithReason(PromiseError.CycleDetected)
            return
        }

        synchronize {
            switch state {
            case .Pending(let info):
                info.clearParent()
                precondition(info.deferred == nil)
                info.deferred = promise.then(
                    onFulfilled: { [weak self] value in
                        let fulfilled = Promise<T>(fulfill: value)
                        
                        if let strongSelf = self {
                            strongSelf.resolve(fulfilled)
                        }
                        
                        return fulfilled
                    },
                    onRejected: { [weak self] reason in
                        let rejected = Promise<T>(reject: reason)
                        
                        if let strongSelf = self {
                            strongSelf.resolve(rejected)
                        }
                        
                        return rejected
                    }
                )
            default:
                return
            }
        }
    }
    
    public func then<R>(onFulfilled onFulfilled: (T) throws -> Promise<R>, onRejected: (ErrorType) throws -> Promise<R>) -> Promise<R> {
        return Promise<R>(parent: {self}) { resolve in
            let fulfiller: (T) -> Void = { value in
                do {
                    resolve(try onFulfilled(value))
                }
                catch {
                    resolve(Promise<R>(reject: error))
                }
            }
            
            let rejecter: (ErrorType) -> Void = { reason in
                do {
                    resolve(try onRejected(reason))
                }
                catch {
                    resolve(Promise<R>(reject: error))
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
        }
    }
    
    public func then(onFulfilled: (T) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { value in
                try onFulfilled(value)
                return Promise<T>(fulfill: value)
            },
            onRejected: { reason in
                return Promise<T>(reject: reason)
            }
        )
    }
    
    public func then<C: AnyObject>(context: C, _ onFulfilled: (C, T) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    try onFulfilled(strongContext, value)
                }
                
                return Promise<T>(fulfill: value)
            },
            onRejected: { reason in
                throw reason
            }
        )
    }
    
    public func then<R>(onFulfilled: (T) throws -> Promise<R>) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { reason in
                throw reason
            }
        )
    }
    
    public func then<C: AnyObject, R>(context: C, _ onFulfilled: (C, T) throws -> Promise<R>) -> Promise<R> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    return try onFulfilled(strongContext, value)
                } else {
                    return Promise<R>(reject: PromiseError.ContextUnavailable)
                }
            },
            onRejected: { reason in
                throw reason
            }
        )
    }
    
    public func handle(onRejected: (ErrorType) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return Promise<T>(fulfill: value)
            },
            onRejected: { reason in
                try onRejected(reason)
                
                throw reason
            }
        )
    }
    
    public func handle<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) throws -> Void) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return Promise<T>(fulfill: value)
            },
            onRejected: { [weak context] reason in
                if let strongContext = context {
                    try onRejected(strongContext, reason)
                }
                
                throw reason
            }
        )
    }
    
    public func recover(onRejected: (ErrorType) throws -> Promise<T>) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return Promise<T>(fulfill: value)
            },
            onRejected: onRejected
        )
    }

    public func recover<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) throws -> Promise<T>) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return Promise<T>(fulfill: value)
            },
            onRejected: { [weak context] reason in
                if let strongContext = context {
                    return try onRejected(strongContext, reason)
                } else {
                    throw reason
                }
            }
        )
    }
    
    public func finally(onFinally: () -> Void) -> Promise<T> {
        return then(
            onFulfilled: { value in
                onFinally()
                return Promise<T>(fulfill: value)
            },
            onRejected: { reason in
                onFinally()
                return Promise<T>(reject: reason)
            }
        )
    }
    
    public func finally<C: AnyObject>(context: C, _ onFinally: (C) -> Void) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                
                return Promise<T>(fulfill: value)
            },
            onRejected: { [weak context] reason in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                
                return Promise<T>(reject: reason)
            }
        )
    }
}
