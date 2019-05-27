/*
 The MIT License (MIT)
 
 Copyright (c) 2018 Justin Kolb
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

public final class Promise<Value> {
    private let lock: Lock
    private var state: State<Value>
    
    public init(_ promise: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void, _ isCancelled: @escaping () -> Bool) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred())

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        promise(weakify(Promise.fulfill), weakify(Promise.reject), isCancelled)
    }

    private func weakify<V>(_ method: @escaping (Promise) -> (V) -> Void) -> (V) -> Void {
        return { [weak self] (value: V) in
            guard let self = self else { return }
            
            method(self)(value)
        }
    }

    public func then<ThenValue>(on executionContext: ExecutionContext, onFulfilled: @escaping (Value) throws -> Promised<ThenValue>, onRejected: @escaping (Error) throws -> Promised<ThenValue>) -> Promise<ThenValue> {
        return Promise<ThenValue>(pendingPromise: self) { (resolve, reject) in
            self.onResolve(
                fulfill: { (value) in
                    executionContext.execute {
                        do {
                            let result = try onFulfilled(value)
                            resolve(result)
                        }
                        catch {
                            reject(error)
                        }
                    }
                },
                reject: { (reason) in
                    executionContext.execute {
                        do {
                            let result = try onRejected(reason)
                            resolve(result)
                        }
                        catch {
                            reject(error)
                        }
                    }
                }
            )
        }
    }
    
    init(pending: Any, _ resolver: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred(pending: pending))
        
        resolver(weakify(Promise.fulfill), weakify(Promise.reject))
    }

    private init<PendingValue>(pendingPromise: Promise<PendingValue>, _ resolver: (_ resolve: @escaping (Promised<Value>) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred(pendingPromise: pendingPromise))
        
        resolver(weakify(Promise.resolve), weakify(Promise.reject))
    }
    
    private func fulfill(_ value: Value) {
        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .fulfilled(value)
            lock.unlock()
            
            for onFulfilled in deferred.onFulfilled {
                onFulfilled(value)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func reject(_ reason: Error) {
        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .rejected(reason)
            lock.unlock()
            
            for onRejected in deferred.onRejected {
                onRejected(reason)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func pendOn(_ promise: Promise<Value>) {
        precondition(promise !== self)

        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .pending(Deferred(pendingPromise: promise, onFulfilled: deferred.onFulfilled, onRejected: deferred.onRejected))
            lock.unlock()
            promise.onResolve(fulfill: weakify(Promise.fulfill), reject: weakify(Promise.reject))
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }

    private func resolve(_ result: Promised<Value>) {
        switch result {
        case .value(let value):
            fulfill(value)
            
        case .promise(let promise):
            pendOn(promise)
        }
    }
    
    func onResolve(fulfill: @escaping (Value) -> Void, reject: @escaping (Error) -> Void) {
        lock.lock()
        
        switch state {
        case .fulfilled(let value):
            lock.unlock()
            fulfill(value)
            
        case .rejected(let reason):
            lock.unlock()
            reject(reason)
            
        case .pending(let deferred):
            deferred.onFulfilled.append(fulfill)
            deferred.onRejected.append(reject)
            lock.unlock()
        }
    }
}

public extension Promise {
    func whenFulfilledThenMap<ResultingValue>(on executionContext: ExecutionContext, map: @escaping (Value) throws -> Promised<ResultingValue>) -> Promise<ResultingValue> {
        return then(
            on: executionContext,
            onFulfilled: { (value) throws -> Promised<ResultingValue> in
                return try map(value)
            },
            onRejected: { (reason) throws -> Promised<ResultingValue> in
                throw reason
            }
        )
    }
    
    func whenFulfilled(on executionContext: ExecutionContext, thenDo: @escaping (Value) throws -> Void) -> Promise<Value> {
        return whenFulfilledThenMap(on: executionContext) { (value) throws -> Promised<Value> in
            try thenDo(value)
            
            return .value(value)
        }
    }
    
    func whenFulfilledThenTransform<ResultingValue>(on executionContext: ExecutionContext, transform: @escaping (Value) throws -> ResultingValue) -> Promise<ResultingValue> {
        return whenFulfilledThenMap(on: executionContext) { (value) throws -> Promised<ResultingValue> in
            let result = try transform(value)
            
            return .value(result)
        }
    }
    
    func whenFulfilledThenPromise<ResultingValue>(on executionContext: ExecutionContext, promise: @escaping (Value) throws -> Promise<ResultingValue>) -> Promise<ResultingValue> {
        return whenFulfilledThenMap(on: executionContext) { (value) throws -> Promised<ResultingValue> in
            let result = try promise(value)
            
            return .promise(result)
        }
    }
    
    func whenRejectedThenMap(on executionContext: ExecutionContext, map: @escaping (Error) throws -> Promised<Value>) -> Promise<Value> {
        return then(
            on: executionContext,
            onFulfilled: { (value) throws -> Promised<Value> in
                return .value(value)
            },
            onRejected: { (reason) throws -> Promised<Value> in
                let result = try map(reason)
                
                return result
            }
        )
    }
    
    func whenRejected(on executionContext: ExecutionContext, thenDo: @escaping (Error) throws -> Void) -> Promise<Value> {
        return whenRejectedThenMap(on: executionContext) { (reason) throws -> Promised<Value> in
            try thenDo(reason)
            
            throw reason
        }
    }
    
    func whenRejectedThenTransform(on executionContext: ExecutionContext, transform: @escaping (Error) throws -> Value) -> Promise<Value> {
        return whenRejectedThenMap(on: executionContext) { (reason) throws -> Promised<Value> in
            let result = try transform(reason)
            
            return .value(result)
        }
    }
    
    func whenRejectedThenPromise(on executionContext: ExecutionContext, promise: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return whenRejectedThenMap(on: executionContext) { (reason) throws -> Promised<Value> in
            let result = try promise(reason)
            
            return .promise(result)
        }
    }
    
    func whenComplete(on executionContext: ExecutionContext, thenDo: @escaping () -> Void) -> Promise<Value> {
        return then(
            on: executionContext,
            onFulfilled: { (value) throws -> Promised<Value> in
                thenDo()
                
                return .value(value)
            },
            onRejected: { (reason) throws -> Promised<Value> in
                thenDo()
                
                throw reason
            }
        )
    }
}
