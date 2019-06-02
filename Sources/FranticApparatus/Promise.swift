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
        private let fulfilled: (Value) -> Void
        private let rejected: (Error) -> Void
        
        init(context: ExecutionContext, fulfilled: @escaping (Value) -> Void, rejected: @escaping (Error) -> Void) {
            self.context = context
            self.fulfilled = fulfilled
            self.rejected = rejected
        }
        
        func fulfill(value: Value) {
            context.execute {
                self.fulfilled(value)
            }
        }
        
        func reject(reason: Error) {
            context.execute {
                self.rejected(reason)
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

    public func then(on context: ExecutionContext, _ fulfilled: @escaping (Value) -> Void) -> Promise<Value> {
        return then(on: context, fulfilled: { fulfilled($0); return .value($0) }, rejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext, map: @escaping (Value) throws -> Other) -> Promise<Other> {
        return then(on: context, fulfilled: { try .value(map($0)) }, rejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext, promise: @escaping (Value) throws -> Promise<Other>) -> Promise<Other> {
        return then(on: context, fulfilled: { try .promise(promise($0)) }, rejected: { throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext, transform: @escaping (Value) throws -> Result<Other>) -> Promise<Other> {
        return then(on: context, fulfilled: transform, rejected: { throw $0 })
    }
    
    public func `catch`(on context: ExecutionContext, _ rejected: @escaping (Error) -> Void) -> Promise<Value> {
        return then(on: context, fulfilled: { .value($0) }, rejected: { rejected($0); throw $0 })
    }
    
    public func `catch`(on context: ExecutionContext, map: @escaping (Error) throws -> Value) -> Promise<Value> {
        return then(on: context, fulfilled: { .value($0) }, rejected: { try .value(map($0)) })
    }
    
    public func `catch`(on context: ExecutionContext, promise: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return then(on: context, fulfilled: { .value($0) }, rejected: { try .promise(promise($0)) })
    }
    
    public func `catch`(on context: ExecutionContext, transform: @escaping (Error) throws -> Result<Value>) -> Promise<Value> {
        return then(on: context, fulfilled: { .value($0) }, rejected: transform)
    }
    
    public func finally(on context: ExecutionContext, _ always: @escaping () -> Void) -> Promise<Value> {
        return then(on: context, fulfilled: { always(); return .value($0) }, rejected: { always(); throw $0 })
    }
    
    public func then<Other>(on context: ExecutionContext, fulfilled: @escaping (Value) throws -> Result<Other>, rejected: @escaping (Error) throws -> Result<Other>) -> Promise<Other> {
        return Promise<Other>(pending: { (resolve, reject) in
            self.addCallback(context: context, fulfilled: { (value) in
                do {
                    resolve(context, try fulfilled(value))
                }
                catch {
                    reject(error)
                }
            }, rejected: { (reason) in
                do {
                    resolve(context, try rejected(reason))
                }
                catch {
                    reject(error)
                }
            })
        })
    }
    
    private func fulfill(_ value: Value) {
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
    
    private func reject(_ reason: Error) {
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
    
    private func pending(_ promise: Promise<Value>) {
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
            fulfill(value)
            
        case .promise(let promise):
            pending(promise)
            promise.addCallback(context: context, fulfilled: fulfill, rejected: reject)
        }
    }
    
    func addCallback(context: ExecutionContext, fulfilled: @escaping (Value) -> Void, rejected: @escaping (Error) -> Void) {
        let callback = Callback(context: context, fulfilled: fulfilled, rejected: rejected)
        
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
