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

public protocol Thenable : class {
    associatedtype Value
    
    func thenOn<ResultingValue>(_ dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> Promise<ResultingValue>
}

public extension Thenable {
    public func thenOn<ResultingValue>(_ dispatcher: Dispatcher, _ onFulfilled: @escaping (Value) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return thenOn(
            dispatcher,
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func thenOn(_ dispatcher: Dispatcher, _ onFulfilled: @escaping (Value) throws -> Void) -> Promise<Value> {
        return thenOn(dispatcher) { (value) throws -> Result<Value> in
            try onFulfilled(value)
            
            return .value(value)
        }
    }
    
    public func thenOn<ResultingValue>(_ dispatcher: Dispatcher, _ onFulfilled: @escaping (Value) throws -> ResultingValue) -> Promise<ResultingValue> {
        return thenOn(dispatcher) { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .value(result)
        }
    }
    
    public func thenOn<ResultingValue>(_ dispatcher: Dispatcher, _ onFulfilled: @escaping (Value) throws -> Promise<ResultingValue>) -> Promise<ResultingValue> {
        return thenOn(dispatcher) { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .promise(result)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultingValue>(_ dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return thenOn(dispatcher) { [weak object] (value) -> Result<ResultingValue> in
            guard let object = object else { throw PromiseError.objectDeallocated }
            
            let result = try onFulfilled(object, value)
            
            return result
        }
    }
    
    public func thenOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Void) -> Promise<Value> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<Value> in
            try onFulfilled(object, value)
            
            return .value(value)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultingValue>(_ dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: @escaping (Object, Value) throws -> ResultingValue) -> Promise<ResultingValue> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(object, value)
            
            return .value(result)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultingValue>(_ dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: @escaping (Object, Value) throws -> Promise<ResultingValue>) -> Promise<ResultingValue> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(object, value)
            
            return .promise(result)
        }
    }
    
    public func handleOn(_ dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Result<Value>) -> Promise<Value> {
        return thenOn(
            dispatcher,
            onFulfilled: { (value) throws -> Result<Value> in
                return .value(value)
            },
            onRejected: { (reason) throws -> Result<Value> in
                let result = try onRejected(reason)
                
                return result
            }
        )
    }
    
    public func handleOn(_ dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Void) -> Promise<Value> {
        return handleOn(dispatcher) { (reason) throws -> Result<Value> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handleOn(_ dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Value) -> Promise<Value> {
        return handleOn(dispatcher) { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .value(result)
        }
    }
    
    public func handleOn(_ dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return handleOn(dispatcher) { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .promise(result)
        }
    }
    
    public func handleOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onRejected: @escaping (Object, Error) throws -> Result<Value>) -> Promise<Value> {
        return handleOn(dispatcher) { [weak object] (reason) -> Result<Value> in
            guard let object = object else { throw PromiseError.objectDeallocated }
            
            let result = try onRejected(object, reason)
            
            return result
        }
    }
    
    public func handleOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onRejected: @escaping (Object, Error) throws -> Void) -> Promise<Value> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<Value> in
            try onRejected(object, reason)
            
            throw reason
        }
    }
    
    public func handleOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onRejected: @escaping (Object, Error) throws -> Value) -> Promise<Value> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<Value> in
            let result = try onRejected(object, reason)
            
            return .value(result)
        }
    }
    
    public func handleOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onRejected: @escaping (Object, Error) throws -> Promise<Value>) -> Promise<Value> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<Value> in
            let result = try onRejected(object, reason)
            
            return .promise(result)
        }
    }
    
    public func finallyOn(_ dispatcher: Dispatcher, _ onFinally: @escaping () -> Void) -> Promise<Value> {
        return thenOn(
            dispatcher,
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
    
    public func finallyOn<Object: AnyObject>(_ dispatcher: Dispatcher, withObject object: Object, _ onFinally: @escaping (Object) -> Void) -> Promise<Value> {
        return finallyOn(dispatcher) { [weak object] in
            guard let object = object else { return }
            
            onFinally(object)
        }
    }
}
