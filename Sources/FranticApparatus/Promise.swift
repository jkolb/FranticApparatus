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

public enum Result<Value> {
    case value(Value)
    case promise(Promise<Value>)
}

public final class Promise<Value> {
    private enum State {
        case pending(Deferred)
        case fulfilled(Value)
        case rejected(Error)
    }

    private final class Deferred {
        private let pending: Any?
        var onFulfilled: [(Value) -> Void]
        var onRejected: [(Error) -> Void]
        
        convenience init() {
            self.init(pending: nil, onFulfilled: [], onRejected: [])
        }
        
        convenience init(pending: Any) {
            self.init(pending: pending, onFulfilled: [], onRejected: [])
        }
        
        convenience init<P>(pendingPromise: Promise<P>?) {
            self.init(pending: pendingPromise, onFulfilled: [], onRejected: [])
        }
        
        convenience init<P>(pendingPromise: Promise<P>, onFulfilled: [(Value) -> Void], onRejected: [(Error) -> Void]) {
            self.init(pending: pendingPromise, onFulfilled: onFulfilled, onRejected: onRejected)
        }
        
        private init(pending: Any?, onFulfilled: [(Value) -> Void], onRejected: [(Error) -> Void]) {
            self.pending = pending
            self.onFulfilled = onFulfilled
            self.onRejected = onRejected
        }
    }

    private let lock: Lock
    private var state: State
    
    public init(value: Value) {
        self.lock = Lock()
        self.state = .fulfilled(value)
    }

    public init(reason: Error) {
        self.lock = Lock()
        self.state = .rejected(reason)
    }
    
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

    public func then(on executionContext: ExecutionContext = ThreadContext.defaultContext, _ whenFulfilled: @escaping (Value) -> Void) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { whenFulfilled($0); return .value($0) }, whenRejected: { throw $0 })
    }

    public func then<Other>(on executionContext: ExecutionContext = ThreadContext.defaultContext, map: @escaping (Value) throws -> Other) -> Promise<Other> {
        return then(on: executionContext, whenFulfilled: { try .value(map($0)) }, whenRejected: { throw $0 })
    }

    public func then<Other>(on executionContext: ExecutionContext = ThreadContext.defaultContext, promise: @escaping (Value) throws -> Promise<Other>) -> Promise<Other> {
        return then(on: executionContext, whenFulfilled: { try .promise(promise($0)) }, whenRejected: { throw $0 })
    }

    public func then<Other>(on executionContext: ExecutionContext = ThreadContext.defaultContext, _ transform: @escaping (Value) throws -> Result<Other>) -> Promise<Other> {
        return then(on: executionContext, whenFulfilled: transform, whenRejected: { throw $0 })
    }

    public func `catch`(on executionContext: ExecutionContext = ThreadContext.defaultContext, _ whenRejected: @escaping (Error) -> Void) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { .value($0) }, whenRejected: { whenRejected($0); throw $0 })
    }

    public func recover(on executionContext: ExecutionContext = ThreadContext.defaultContext, map: @escaping (Error) throws -> Value) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { .value($0) }, whenRejected: { try .value(map($0)) })
    }

    public func recover(on executionContext: ExecutionContext = ThreadContext.defaultContext, promise: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { .value($0) }, whenRejected: { try .promise(promise($0)) })
    }

    public func recover(on executionContext: ExecutionContext = ThreadContext.defaultContext, _ transform: @escaping (Error) throws -> Result<Value>) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { .value($0) }, whenRejected: transform)
    }

    public func finally(on executionContext: ExecutionContext = ThreadContext.defaultContext, _ always: @escaping () -> Void) -> Promise<Value> {
        return then(on: executionContext, whenFulfilled: { always(); return .value($0) }, whenRejected: { always(); throw $0 })
    }

    public func then<Other>(on executionContext: ExecutionContext = ThreadContext.defaultContext, whenFulfilled: @escaping (Value) throws -> Result<Other>, whenRejected: @escaping (Error) throws -> Result<Other>) -> Promise<Other> {
        return Promise<Other>(pendingPromise: self) { (resolve, reject) in
            self.onResolve(
                fulfill: { (value) in
                    executionContext.execute {
                        do {
                            let result = try whenFulfilled(value)
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
                            let result = try whenRejected(reason)
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

    private init<PendingValue>(pendingPromise: Promise<PendingValue>, _ resolver: (_ resolve: @escaping (Result<Value>) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
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

    private func resolve(_ result: Result<Value>) {
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
