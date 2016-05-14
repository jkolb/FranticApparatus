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
    public func asContextFor<ValueType>(promise: Promise<ValueType>) -> PromiseDispatchContext<ValueType> {
        return PromiseDispatchContext<ValueType>(dispatcher: self, promise: promise)
    }
}

public final class PromiseDispatchContext<ValueType> : Thenable {
    public let dispatcher: Dispatcher
    public let promise: Promise<ValueType>
    
    public init(dispatcher: Dispatcher, promise: Promise<ValueType>) {
        self.dispatcher = dispatcher
        self.promise = promise
    }
    
    public func thenOn<ResultType>(dispatcher: Dispatcher, onFulfilled: (ValueType) throws -> Result<ResultType>, onRejected: (ErrorType) throws -> Result<ResultType>) -> Promise<ResultType> {
        return promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
    }

    public func then<ResultType>(onFulfilled onFulfilled: (ValueType) throws -> Result<ResultType>, onRejected: (ErrorType) throws -> Result<ResultType>) -> PromiseDispatchContext<ResultType> {
        let promise2 = promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
        return PromiseDispatchContext<ResultType>(dispatcher: dispatcher, promise: promise2)
    }
    
    public func then<ResultType>(onFulfilled: (ValueType) throws -> Result<ResultType>) -> PromiseDispatchContext<ResultType> {
        return then(
            onFulfilled: { (value) throws -> Result<ResultType> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultType> in
                throw reason
            }
        )
    }
    
    public func then(onFulfilled: (ValueType) throws -> Void) -> PromiseDispatchContext<ValueType> {
        return then { (value) throws -> Result<ValueType> in
            try onFulfilled(value)
            
            return .Value(value)
        }
    }
    
    public func then<ResultType>(onFulfilled: (ValueType) throws -> ResultType) -> PromiseDispatchContext<ResultType> {
        return then { (value) throws -> Result<ResultType> in
            let result = try onFulfilled(value)
            
            return .Value(result)
        }
    }
    
    public func then<ResultType>(onFulfilled: (ValueType) throws -> Promise<ResultType>) -> PromiseDispatchContext<ResultType> {
        return then { (value) throws -> Result<ResultType> in
            let result = try onFulfilled(value)
            
            return .Defer(result)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultType>(object: Object, _ onFulfilled: (Object, ValueType) throws -> Result<ResultType>) -> PromiseDispatchContext<ResultType> {
        return then { [weak object] (value) -> Result<ResultType> in
            guard let object = object else { throw PromiseError.ObjectUnavailable }
            
            let result = try onFulfilled(object, value)
            
            return result
        }
    }
    
    public func thenWithObject<Object: AnyObject>(object: Object, _ onFulfilled: (Object, ValueType) throws -> Void) -> PromiseDispatchContext<ValueType> {
        return thenWithObject(object) { (object, value) throws -> Result<ValueType> in
            try onFulfilled(object, value)
            
            return .Value(value)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultType>(object: Object, _ onFulfilled: (Object, ValueType) throws -> ResultType) -> PromiseDispatchContext<ResultType> {
        return thenWithObject(object) { (object, value) throws -> Result<ResultType> in
            let result = try onFulfilled(object, value)
            
            return .Value(result)
        }
    }
    
    public func thenWithObject<Object: AnyObject, ResultType>(object: Object, _ onFulfilled: (Object, ValueType) throws -> Promise<ResultType>) -> PromiseDispatchContext<ResultType> {
        return thenWithObject(object) { (object, value) throws -> Result<ResultType> in
            let result = try onFulfilled(object, value)
            
            return .Defer(result)
        }
    }
    
    public func handle(onRejected: (ErrorType) throws -> Result<ValueType>) -> PromiseDispatchContext<ValueType> {
        return then(
            onFulfilled: { (value) throws -> Result<ValueType> in
                return .Value(value)
            },
            onRejected: { (reason) throws -> Result<ValueType> in
                let result = try onRejected(reason)
                
                return result
            }
        )
    }
    
    public func handle(onRejected: (ErrorType) throws -> Void) -> PromiseDispatchContext<ValueType> {
        return handle { (reason) throws -> Result<ValueType> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handle(onRejected: (ErrorType) throws -> ValueType) -> PromiseDispatchContext<ValueType> {
        return handle { (reason) throws -> Result<ValueType> in
            let result = try onRejected(reason)
            
            return .Value(result)
        }
    }
    
    public func handle(onRejected: (ErrorType) throws -> Promise<ValueType>) -> PromiseDispatchContext<ValueType> {
        return handle { (reason) throws -> Result<ValueType> in
            let result = try onRejected(reason)
            
            return .Defer(result)
        }
    }
    
    public func handleWithObject<Object: AnyObject>(object: Object, _ onRejected: (Object, ErrorType) throws -> Result<ValueType>) -> PromiseDispatchContext<ValueType> {
        return handle { [weak object] (reason) -> Result<ValueType> in
            guard let object = object else { throw PromiseError.ObjectUnavailable }
            
            let result = try onRejected(object, reason)
            
            return result
        }
    }
    
    public func handleWithObject<Object: AnyObject>(object: Object, _ onRejected: (Object, ErrorType) throws -> Void) -> PromiseDispatchContext<ValueType> {
        return handleWithObject(object) { (object, reason) throws -> Result<ValueType> in
            try onRejected(object, reason)
            
            throw reason
        }
    }
    
    public func handleWithObject<Object: AnyObject>(object: Object, _ onRejected: (Object, ErrorType) throws -> ValueType) -> PromiseDispatchContext<ValueType> {
        return handleWithObject(object) { (object, reason) throws -> Result<ValueType> in
            let result = try onRejected(object, reason)
            
            return .Value(result)
        }
    }
    
    public func handleWithObject<Object: AnyObject>(object: Object, _ onRejected: (Object, ErrorType) throws -> Promise<ValueType>) -> PromiseDispatchContext<ValueType> {
        return handleWithObject(object) { (object, reason) throws -> Result<ValueType> in
            let result = try onRejected(object, reason)
            
            return .Defer(result)
        }
    }
    
    public func finally(onFinally: () -> Void) -> PromiseDispatchContext<ValueType> {
        return then(
            onFulfilled: { (value) throws -> Result<ValueType> in
                onFinally()
                
                return .Value(value)
            },
            onRejected: { (reason) throws -> Result<ValueType> in
                onFinally()
                
                throw reason
            }
        )
    }
    
    public func finallyWithObject<Object: AnyObject>(object: Object, _ onFinally: (Object) -> Void) -> PromiseDispatchContext<ValueType> {
        return finally { [weak object] in
            guard let object = object else { return }
            
            onFinally(object)
        }
    }
}
