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

public enum PromiseError : ErrorType {
    case ContextUnavailable
}

private class PendingInfo<T> {
    let parent: (() -> Any)?
    var deferred: Promise<T>? = nil
    var onFulfilled: Array<T -> ()> = []
    var onRejected: Array<ErrorType -> ()> = []
    
    private init() {
        self.parent = nil
    }

    private init(parent: () -> Any) {
        self.parent = parent
    }
}

private enum State<T> {
    case Pending(PendingInfo<T>)
    case Fulfilled(T)
    case Rejected(ErrorType)
}

public enum Result<T> {
    case Success(T)
    case Deferred(Promise<T>)
    case Failure(ErrorType)
}

public class Promise<T> : Synchronizable {
    public let synchronizationQueue: DispatchQueue
    private var state: State<T>
    
    public init(_ resolver: (fulfill: T -> (), reject: ErrorType -> (), isCancelled: () -> Bool) -> ()) {
        self.state = .Pending(PendingInfo())
        self.synchronizationQueue = GCDQueue.serial("net.franticapparatus.Promise")
        
        let weakFulfill: T -> () = { [weak self] value in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(.Success(value))
            }
        }
        
        let weakReject: ErrorType -> () = { [weak self] reason in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(.Failure(reason))
            }
        }

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        resolver(fulfill: weakFulfill, reject: weakReject, isCancelled: isCancelled)
    }
    
    private init(parent: () -> Any, synchronizationQueue: DispatchQueue, resolver: (Result<T> -> ()) -> ()) {
        self.state = .Pending(PendingInfo(parent: parent))
        self.synchronizationQueue = synchronizationQueue
        
        let weakResolve: Result<T> -> () = { [weak self] result in
            if let strongSelf = self {
                Promise<T>.resolve(strongSelf)(result)
            }
        }
        
        resolver(weakResolve)
    }
    
    private func resolve(result: Result<T>) {
        synchronizeWrite(self) { promise in
            promise.transition(result)
        }
    }
    
    private func transition(result: Result<T>) {
        switch self.state {
        case .Pending(let info):
            switch result {
            case .Success(let value):
                self.state = .Fulfilled(value)
                for fulfillHandler in info.onFulfilled {
                    fulfillHandler(value)
                }
            case .Failure(let reason):
                self.state = .Rejected(reason)
                for rejectHandler in info.onRejected {
                    rejectHandler(reason)
                }
            case .Deferred(let promise):
                assert(promise !== self, "A promise referencing itself causes an unbreakable retain cycle")
                info.deferred = promise.thenOn(
                    synchronizationQueue,
                    onFulfilled: { [weak self] value in
                        let valueResult: Result<T> = .Success(value)
                        if let strongSelf = self {
                            strongSelf.transition(valueResult)
                        }
                        return valueResult
                    },
                    onRejected: { [weak self] reason in
                        let reasonResult: Result<T> = .Failure(reason)
                        if let strongSelf = self {
                            strongSelf.transition(reasonResult)
                        }
                        return reasonResult
                    }
                )
            }
        default:
            return
        }
    }
    
    public func then<R>(onFulfilled onFulfilled: T -> Result<R>, onRejected: ErrorType -> Result<R>) -> Promise<R> {
        return thenOn(GCDQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    public func thenOn<R>(thenQueue: DispatchQueue, onFulfilled: T -> Result<R>, onRejected: ErrorType -> Result<R>) -> Promise<R> {
        return Promise<R>(parent: {self}, synchronizationQueue: synchronizationQueue) { resolve in
            let fulfiller: T -> () = { value in
                thenQueue.dispatch {
                    let result = onFulfilled(value)
                    resolve(result)
                }
            }
            let rejecter: ErrorType -> () = { reason in
                thenQueue.dispatch {
                    let result = onRejected(reason)
                    resolve(result)
                }
            }
            
            synchronizeWrite(self) { parent in
                switch parent.state {
                case .Pending(let info):
                    info.onFulfilled.append(fulfiller)
                    info.onRejected.append(rejecter)
                case .Fulfilled(let value):
                    fulfiller(value)
                case .Rejected(let reason):
                    rejecter(reason)
                }
            }
        }
    }
    
    public func then(onFulfilled: T -> ()) -> Promise<T> {
        return then(
            onFulfilled: { value in
                onFulfilled(value)
                return .Success(value)
            },
            onRejected: { reason in
                return .Failure(reason)
            }
        )
    }
    
    public func then<C: AnyObject>(context: C, _ onFulfilled: (C, T) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    onFulfilled(strongContext, value)
                }
                return .Success(value)
            },
            onRejected: { reason in
                return .Failure(reason)
            }
        )
    }
    
    public func then<R>(onFulfilled: T -> Result<R>) -> Promise<R> {
        return then(
            onFulfilled: onFulfilled,
            onRejected: { reason in
                return .Failure(reason)
            }
        )
    }
    
    public func then<C: AnyObject, R>(context: C, _ onFulfilled: (C, T) -> Result<R>) -> Promise<R> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    return onFulfilled(strongContext, value)
                } else {
                    return .Failure(PromiseError.ContextUnavailable)
                }
            },
            onRejected: { reason in
                return .Failure(reason)
            }
        )
    }
    
    public func handle(onRejected: ErrorType -> ()) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return .Success(value)
            },
            onRejected: { reason in
                onRejected(reason)
                return .Failure(reason)
            }
        )
    }
    
    public func handle<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) -> ()) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return .Success(value)
            },
            onRejected: { [weak context] reason in
                if let strongContext = context {
                    onRejected(strongContext, reason)
                }
                return .Failure(reason)
            }
        )
    }
    
    public func recover(onRejected: ErrorType -> Result<T>) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return .Success(value)
            },
            onRejected: onRejected
        )
    }
    
    public func recover<C: AnyObject>(context: C, _ onRejected: (C, ErrorType) -> Result<T>) -> Promise<T> {
        return then(
            onFulfilled: { value in
                return .Success(value)
            },
            onRejected: { [weak context] error in
                if let strongContext = context {
                    return onRejected(strongContext, error)
                } else {
                    return .Failure(error)
                }
            }
        )
    }
    
    public func finally(onFinally: () -> ()) -> Promise<T> {
        return then(
            onFulfilled: { value in
                onFinally()
                return .Success(value)
            },
            onRejected: { reason in
                onFinally()
                return .Failure(reason)
            }
        )
    }
    
    public func finally<C: AnyObject>(context: C, _ onFinally: C -> ()) -> Promise<T> {
        return then(
            onFulfilled: { [weak context] value in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                return .Success(value)
            },
            onRejected: { [weak context] reason in
                if let strongContext = context {
                    onFinally(strongContext)
                }
                return .Failure(reason)
            }
        )
    }
}
