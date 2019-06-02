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
        case pending(Promise<Value>?, [Callback])
        case fulfilled(Value)
        case rejected(Error)
    }
    
    struct Callback {
        private let context: ExecutionContext
        private let whenFulfilled: (Value) -> Void
        private let whenRejected: (Error) -> Void
        
        init(context: ExecutionContext, whenFulfilled: @escaping (Value) -> Void, whenRejected: @escaping (Error) -> Void) {
            self.context = context
            self.whenFulfilled = whenFulfilled
            self.whenRejected = whenRejected
        }
        
        func fulfill(value: Value) {
            context.execute {
                self.whenFulfilled(value)
            }
        }
        
        func reject(reason: Error) {
            context.execute {
                self.whenRejected(reason)
            }
        }
    }
    
    private let lock = Lock()
    private var state: State
    
    public init(value: Value) {
        self.state = .fulfilled(value)
    }
    
    public init(reason: Error) {
        self.state = .rejected(reason)
    }
    
    public init(_ promise: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.state = .pending(nil, [])
        promise(fulfill, reject)
    }
    
    private init(pending: (_ resolve: @escaping (ExecutionContext, Result<Value>) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.state = .pending(nil, [])
        pending(resolve, reject)
    }

    public func then(on context: ExecutionContext = ThreadContext.defaultContext, _ use: @escaping (Value) -> Void) -> Promise<Value> {
        return then(on: context, whenFulfilled: { use($0); return .value($0) }, whenRejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext = ThreadContext.defaultContext, map: @escaping (Value) throws -> Other) -> Promise<Other> {
        return then(on: context, whenFulfilled: { try .value(map($0)) }, whenRejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext = ThreadContext.defaultContext, promise: @escaping (Value) throws -> Promise<Other>) -> Promise<Other> {
        return then(on: context, whenFulfilled: { try .promise(promise($0)) }, whenRejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext = ThreadContext.defaultContext, transform: @escaping (Value) throws -> Result<Other>) -> Promise<Other> {
        return then(on: context, whenFulfilled: transform, whenRejected: { throw $0 })
    }
    
    public func `catch`(on context: ExecutionContext = ThreadContext.defaultContext, _ use: @escaping (Error) -> Void) -> Promise<Value> {
        return then(on: context, whenFulfilled: { .value($0) }, whenRejected: { use($0); throw $0 })
    }
    
    public func `catch`(on context: ExecutionContext = ThreadContext.defaultContext, map: @escaping (Error) throws -> Value) -> Promise<Value> {
        return then(on: context, whenFulfilled: { .value($0) }, whenRejected: { try .value(map($0)) })
    }
    
    public func `catch`(on context: ExecutionContext = ThreadContext.defaultContext, promise: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return then(on: context, whenFulfilled: { .value($0) }, whenRejected: { try .promise(promise($0)) })
    }
    
    public func `catch`(on context: ExecutionContext = ThreadContext.defaultContext, transform: @escaping (Error) throws -> Result<Value>) -> Promise<Value> {
        return then(on: context, whenFulfilled: { .value($0) }, whenRejected: transform)
    }
    
    public func finally(on context: ExecutionContext = ThreadContext.defaultContext, _ always: @escaping () -> Void) -> Promise<Value> {
        return then(on: context, whenFulfilled: { always(); return .value($0) }, whenRejected: { always(); throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext = ThreadContext.defaultContext, whenFulfilled: @escaping (Value) throws -> Result<Other>, whenRejected: @escaping (Error) throws -> Result<Other>) -> Promise<Other> {
        return Promise<Other>(pending: { (resolve, reject) in
            self.addCallback(context: context, whenFulfilled: { (value) in
                do {
                    resolve(context, try whenFulfilled(value))
                }
                catch {
                    reject(error)
                }
            }, whenRejected: { (reason) in
                do {
                    resolve(context, try whenRejected(reason))
                }
                catch {
                    reject(error)
                }
            })
        })
    }
    
    private func fulfill(value: Value) {
        lock.lock()
        switch state {
        case .pending(_, let callbacks):
            state = .fulfilled(value)
            lock.unlock()
            
            for callback in callbacks {
                callback.fulfill(value: value)
            }

        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func reject(reason: Error) {
        lock.lock()
        switch state {
        case .pending(_, let callbacks):
            state = .rejected(reason)
            lock.unlock()
            
            for callback in callbacks {
                callback.reject(reason: reason)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func pending(promise: Promise<Value>) {
        lock.lock()
        switch state {
        case .pending(_, let callbacks):
            state = .pending(promise, callbacks)
            lock.unlock()
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func resolve(context: ExecutionContext, result: Result<Value>) {
        switch result {
        case .value(let value):
            fulfill(value: value)
            
        case .promise(let promise):
            pending(promise: promise)
            promise.addCallback(context: context, whenFulfilled: fulfill, whenRejected: reject)
        }
    }
    
    func addCallback(context: ExecutionContext, whenFulfilled: @escaping (Value) -> Void, whenRejected: @escaping (Error) -> Void) {
        let callback = Callback(context: context, whenFulfilled: whenFulfilled, whenRejected: whenRejected)
        
        lock.lock()
        
        switch state {
        case .pending(let promise, let callbacks):
            state = .pending(promise, callbacks + [callback])
            lock.unlock()

        case .fulfilled(let value):
            lock.unlock()
            callback.fulfill(value: value)
            
        case .rejected(let reason):
            lock.unlock()
            callback.reject(reason: reason)
        }
    }
}
