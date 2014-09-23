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

import Dispatch

// 2.1 - Promise States
// A promise must be in one of three states: pending, fulfilled, or rejected.
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
    let queue: SerialTaskQueue
    let parent: (() -> Any)?
    var state: State<T> = .Pending
    var deferred: Promise<T>! = nil
    var onFulfilled = Array<(T) -> ()>()
    var onRejected = Array<(Error) -> ()>()
    
    init(queue: SerialTaskQueue = GCDSerialTaskQueue(), parent: (() -> Any)? = nil) {
        self.queue = queue
        self.parent = parent
    }
    
    func fulfill(value: T) {
        queue.dispatch { [weak self] in
            if let blockSelf = self {
                switch blockSelf.state {
                case .Pending:
                    blockSelf.state = .Fulfilled(value)
                    // 2.2.2.2 - it must not be called before promise is fulfilled
                    let callbacks = blockSelf.onFulfilled
                    dispatch_async(dispatch_get_main_queue(), {
                        for callback in callbacks {
                            callback(value)
                        }
                    })
                    blockSelf.onFulfilled.removeAll(keepCapacity: false)
                    blockSelf.onRejected.removeAll(keepCapacity: false)
                default:
                    return
                }
            }
        }
    }
    
    func reject(reason: Error) {
        queue.dispatch { [weak self] in
            if let blockSelf = self {
                switch blockSelf.state {
                case .Pending:
                    blockSelf.state = .Rejected(reason)
                    // 2.2.3.2 - it must not be called before promise is rejected
                    let callbacks = blockSelf.onRejected
                    dispatch_async(dispatch_get_main_queue(), {
                        for callback in callbacks {
                            callback(reason)
                        }
                    })
                    blockSelf.onFulfilled.removeAll(keepCapacity: false)
                    blockSelf.onRejected.removeAll(keepCapacity: false)
                default:
                    return
                }
            }
        }
    }
    
    func resolve<R>(promise: Promise<R>?, result: Result<R>) {
        switch result {
        case .Success(let value):
            promise?.fulfill(value())
        case .Failure(let reason):
            promise?.reject(reason)
        case .Deferred(let deferred):
            switch deferred.state {
            case .Fulfilled(let value):
                promise?.fulfill(value())
            case .Rejected(let reason):
                promise?.reject(reason)
            case .Pending:
                assert(promise? !== deferred, "A promise referencing itself causes an unbreakable retain cycle")
                if promise != nil {
                    assert(promise!.deferred == nil, "Not yet sure if this is possible")
                }
                promise?.deferred = deferred
                deferred.then(
                    // Is it possible for deferred to be set multiple times (losing the intial values)?
                    onFulfilled: { [weak promise] (value: R) -> Result<R> in
                        promise?.fulfill(value)
                        promise?.deferred = nil
                        return .Success(value)
                    },
                    onRejected: { [weak promise] (reason: Error) -> Result<R> in
                        promise?.reject(reason)
                        promise?.deferred = nil
                        return .Failure(reason)
                    }
                )
            }
        }
    }
    
    // 2.2 - The then Method
    // A promise must provide a then method to access its current or eventual value or reason.
    // A promise's then method accepts two arguments: promise.then(onFulfilled, onRejected)
    // 2.2.1 - Both onFulfilled and onRejected are optional arguments
    //    **** Optional versions are provided by the when and catch methods. Being able to
    //    **** provide no callbacks at all (when both are optional) is not useful and is
    //    **** not supported.
    func then<R>(# onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        var promise = Promise<R>(queue: self.queue, parent: {self})

        queue.dispatch { [weak self] in
            if let blockSelf = self {
                switch blockSelf.state {
                case .Pending:
                    blockSelf.onFulfilled.append({ [unowned blockSelf, weak promise] in
                        blockSelf.resolve(promise, result: onFulfilled($0))
                    });
                    
                    blockSelf.onRejected.append({ [unowned blockSelf, weak promise] in
                        blockSelf.resolve(promise, result: onRejected($0))
                    });
                case .Fulfilled(let value):
                    blockSelf.resolve(promise, result: onFulfilled(value()))
                case .Rejected(let reason):
                    blockSelf.resolve(promise, result: onRejected(reason))
                }
            }
        }
        
        return promise
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
