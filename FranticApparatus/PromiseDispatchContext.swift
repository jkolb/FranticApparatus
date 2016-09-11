/*
 The MIT License (MIT)
 
 Copyright (c) 2016 Justin Kolb
 
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

public extension Dispatcher {
    public func asContextFor<Value>(_ promise: Promise<Value>) -> PromiseDispatchContext<Value> {
        return PromiseDispatchContext<Value>(dispatcher: self, promise: promise)
    }
}

public final class PromiseDispatchContext<Value> : Thenable {
    public let dispatcher: Dispatcher
    public let promise: Promise<Value>
    
    public init(dispatcher: Dispatcher, promise: Promise<Value>) {
        self.dispatcher = dispatcher
        self.promise = promise
    }
    
    public func thenOn<ResultingValue>(_ dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
    }

    public func then<ResultingValue>(onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> PromiseDispatchContext<ResultingValue> {
        let promise2 = promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
        return PromiseDispatchContext<ResultingValue>(dispatcher: dispatcher, promise: promise2)
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> Result<ResultingValue>) -> PromiseDispatchContext<ResultingValue> {
        return then(
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func then(_ onFulfilled: @escaping (Value) throws -> Void) -> PromiseDispatchContext<Value> {
        return then { (value) throws -> Result<Value> in
            try onFulfilled(value)
            
            return .value(value)
        }
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> ResultingValue) -> PromiseDispatchContext<ResultingValue> {
        return then { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .value(result)
        }
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> Promise<ResultingValue>) -> PromiseDispatchContext<ResultingValue> {
        return then { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .promise(result)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultingValue>(_ object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Result<ResultingValue>) -> PromiseDispatchContext<ResultingValue> {
        return then { [weak object] (value) -> Result<ResultingValue> in
            guard let object = object else { throw PromiseError.objectDeallocated }
            
            let result = try onFulfilled(object, value)
            
            return result
        }
    }
    
    public func thenWithObject<Object: AnyObject>(_ object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Void) -> PromiseDispatchContext<Value> {
        return thenWithObject(object) { (object, value) throws -> Result<Value> in
            try onFulfilled(object, value)
            
            return .value(value)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultingValue>(_ object: Object, _ onFulfilled: @escaping (Object, Value) throws -> ResultingValue) -> PromiseDispatchContext<ResultingValue> {
        return thenWithObject(object) { (object, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(object, value)
            
            return .value(result)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultingValue>(_ object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Promise<ResultingValue>) -> PromiseDispatchContext<ResultingValue> {
        return thenWithObject(object) { (object, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(object, value)
            
            return .promise(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Result<Value>) -> PromiseDispatchContext<Value> {
        return then(
            onFulfilled: { (value) throws -> Result<Value> in
                return .value(value)
            },
            onRejected: { (reason) throws -> Result<Value> in
                let result = try onRejected(reason)
                
                return result
            }
        )
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Void) -> PromiseDispatchContext<Value> {
        return handle { (reason) throws -> Result<Value> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Value) -> PromiseDispatchContext<Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .value(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Promise<Value>) -> PromiseDispatchContext<Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .promise(result)
        }
    }
    
    public func handleWithObject<Object: AnyObject>(_ object: Object, _ onRejected: @escaping (Object, Error) throws -> Result<Value>) -> PromiseDispatchContext<Value> {
        return handle { [weak object] (reason) -> Result<Value> in
            guard let object = object else { throw PromiseError.objectDeallocated }
            
            let result = try onRejected(object, reason)
            
            return result
        }
    }
    
    public func handleWithObject<Object: AnyObject>(_ object: Object, _ onRejected: @escaping (Object, Error) throws -> Void) -> PromiseDispatchContext<Value> {
        return handleWithObject(object) { (object, reason) throws -> Result<Value> in
            try onRejected(object, reason)
            
            throw reason
        }
    }
    
    public func handleWithObject<Object: AnyObject>(_ object: Object, _ onRejected: @escaping (Object, Error) throws -> Value) -> PromiseDispatchContext<Value> {
        return handleWithObject(object) { (object, reason) throws -> Result<Value> in
            let result = try onRejected(object, reason)
            
            return .value(result)
        }
    }
    
    public func handleWithObject<Object: AnyObject>(_ object: Object, _ onRejected: @escaping (Object, Error) throws -> Promise<Value>) -> PromiseDispatchContext<Value> {
        return handleWithObject(object) { (object, reason) throws -> Result<Value> in
            let result = try onRejected(object, reason)
            
            return .promise(result)
        }
    }
    
    public func finally(_ onFinally: @escaping () -> Void) -> PromiseDispatchContext<Value> {
        return then(
            onFulfilled: { (value) throws -> Result<Value> in
                onFinally()
                
                return .value(value)
            },
            onRejected: { (reason) throws -> Result<Value> in
                onFinally()
                
                throw reason
            }
        )
    }
    
    public func finallyWithObject<Object: AnyObject>(_ object: Object, _ onFinally: @escaping (Object) -> Void) -> PromiseDispatchContext<Value> {
        return finally { [weak object] in
            guard let object = object else { return }
            
            onFinally(object)
        }
    }
}
