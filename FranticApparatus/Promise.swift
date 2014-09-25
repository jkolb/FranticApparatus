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
                blockSelf._fulfill(value)
            }
        }
    }
    
    func _fulfill(value: T) {
        switch state {
        case .Pending:
            state = .Fulfilled(value)
            // 2.2.2.2 - it must not be called before promise is fulfilled
            for fulfillHandler in onFulfilled {
                fulfillHandler(value)
            }
            onFulfilled.removeAll(keepCapacity: false)
            onRejected.removeAll(keepCapacity: false)
        default:
            return
        }
    }
    
    func reject(reason: Error) {
        queue.dispatch { [weak self] in
            if let blockSelf = self {
                blockSelf._reject(reason)
            }
        }
    }
    
    func _reject(reason: Error) {
        switch state {
        case .Pending:
            state = .Rejected(reason)
            // 2.2.3.2 - it must not be called before promise is rejected
            for rejectHandler in onRejected {
                rejectHandler(reason)
            }
            onFulfilled.removeAll(keepCapacity: false)
            onRejected.removeAll(keepCapacity: false)
        default:
            return
        }
    }
    
    func resolve<R>(promise: Promise<R>, result: Result<R>) {
        switch result {
        case .Success(let value):
            promise._fulfill(value())
        case .Failure(let reason):
            promise._reject(reason)
        case .Deferred(let deferred):
            switch deferred.state {
            case .Fulfilled(let value):
                promise._fulfill(value())
            case .Rejected(let reason):
                promise._reject(reason)
            case .Pending:
                assert(promise !== deferred, "A promise referencing itself causes an unbreakable retain cycle")
                assert(promise.deferred == nil, "Not yet sure if this is possible")
                promise.deferred = deferred
                deferred.thenOn(
                    promise.queue,
                    // Is it possible for deferred to be set multiple times (losing the intial values)?
                    onFulfilled: { [weak promise] (value: R) -> Result<R> in
                        if let blockPromise = promise {
                            blockPromise._fulfill(value)
                            blockPromise.deferred = nil
                        }
                        return .Success(value)
                    },
                    onRejected: { [weak promise] (reason: Error) -> Result<R> in
                        if let blockPromise = promise {
                            blockPromise._reject(reason)
                            blockPromise.deferred = nil
                        }
                        return .Failure(reason)
                    }
                )
            }
        }
    }
    
    func dispatch<R>(queue: SerialTaskQueue, promise: Promise<R>, task: (blockSelf: Promise<T>, blockPromise: Promise<R>) -> ()) {
        queue.dispatch { [weak self, weak promise] in
            if let blockSelf = self {
                if let blockPromise = promise {
                    task(blockSelf: blockSelf, blockPromise: blockPromise)
                }
            }
        }
    }
    
    func fulfillHandler<R>(thenQueue: SerialTaskQueue, promise: Promise<R>, onFulfilled: ((T) -> Result<R>)) -> (T) -> () {
        return { [weak self, weak promise] (value: T) -> () in
            if let blockSelf = self {
                if let blockPromise = promise {
                    blockSelf.dispatch(thenQueue, promise: blockPromise) { (blockSelf, blockPromise) -> () in
                        let result = onFulfilled(value)
                        
                        blockSelf.dispatch(blockSelf.queue, promise: blockPromise) { (blockSelf, blockPromise) -> () in
                            blockSelf.resolve(blockPromise, result: result)
                        }
                    }
                }
            }
        }
    }
    
    func rejectHandler<R>(thenQueue: SerialTaskQueue, promise: Promise<R>, onRejected: ((Error) -> Result<R>)) -> (Error) -> () {
        return { [weak self, weak promise] (reason: Error) -> () in
            if let blockSelf = self {
                if let blockPromise = promise {
                    blockSelf.dispatch(thenQueue, promise: blockPromise) { (blockSelf, blockPromise) -> () in
                        let result = onRejected(reason)
                        
                        blockSelf.dispatch(blockSelf.queue, promise: blockPromise) { (blockSelf, blockPromise) -> () in
                            blockSelf.resolve(blockPromise, result: result)
                        }
                    }
                }
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
        return thenOn(GCDSerialTaskQueue.main(), onFulfilled: onFulfilled, onRejected: onRejected)
    }

    func thenOn<R>(thenQueue: SerialTaskQueue, onFulfilled: ((T) -> Result<R>), onRejected: ((Error) -> Result<R>)) -> Promise<R> {
        var promise = Promise<R>(queue: self.queue, parent: {self})
        let fulfillHandler = self.fulfillHandler(thenQueue, promise: promise, onFulfilled: onFulfilled)
        let rejectHandler = self.rejectHandler(thenQueue, promise: promise, onRejected: onRejected)
        
        queue.dispatch { [weak self] in
            if let blockSelf = self {
                switch blockSelf.state {
                case .Pending:
                    blockSelf.onFulfilled.append(fulfillHandler);
                    blockSelf.onRejected.append(rejectHandler);
                case .Fulfilled(let value):
                    fulfillHandler(value())
                case .Rejected(let reason):
                    rejectHandler(reason)
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
