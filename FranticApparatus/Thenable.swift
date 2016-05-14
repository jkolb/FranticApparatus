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
    associatedtype ValueType
    
    func thenOn<ResultType>(dispatcher: Dispatcher, onFulfilled: (ValueType) throws -> Result<ResultType>, onRejected: (ErrorType) throws -> Result<ResultType>) -> Promise<ResultType>
}

public extension Thenable {
    public func thenOn<ResultType>(dispatcher: Dispatcher, _ onFulfilled: (ValueType) throws -> Result<ResultType>) -> Promise<ResultType> {
        return thenOn(
            dispatcher,
            onFulfilled: { (value) throws -> Result<ResultType> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultType> in
                throw reason
            }
        )
    }
    
    public func thenOn(dispatcher: Dispatcher, _ onFulfilled: (ValueType) throws -> Void) -> Promise<ValueType> {
        return thenOn(dispatcher) { (value) throws -> Result<ValueType> in
            try onFulfilled(value)
            
            return .Value(value)
        }
    }
    
    public func thenOn<ResultType>(dispatcher: Dispatcher, _ onFulfilled: (ValueType) throws -> ResultType) -> Promise<ResultType> {
        return thenOn(dispatcher) { (value) throws -> Result<ResultType> in
            let result = try onFulfilled(value)
            
            return .Value(result)
        }
    }
    
    public func thenOn<ResultType>(dispatcher: Dispatcher, _ onFulfilled: (ValueType) throws -> Promise<ResultType>) -> Promise<ResultType> {
        return thenOn(dispatcher) { (value) throws -> Result<ResultType> in
            let result = try onFulfilled(value)
            
            return .Defer(result)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultType>(dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: (Object, ValueType) throws -> Result<ResultType>) -> Promise<ResultType> {
        return thenOn(dispatcher) { [weak object] (value) -> Result<ResultType> in
            guard let object = object else { throw PromiseError.ObjectUnavailable }
            
            let result = try onFulfilled(object, value)
            
            return result
        }
    }
    
    public func thenOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: (Object, ValueType) throws -> Void) -> Promise<ValueType> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<ValueType> in
            try onFulfilled(object, value)
            
            return .Value(value)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultType>(dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: (Object, ValueType) throws -> ResultType) -> Promise<ResultType> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<ResultType> in
            let result = try onFulfilled(object, value)
            
            return .Value(result)
        }
    }
    
    public func thenOn<Object: AnyObject, ResultType>(dispatcher: Dispatcher, withObject object: Object, _ onFulfilled: (Object, ValueType) throws -> Promise<ResultType>) -> Promise<ResultType> {
        return thenOn(dispatcher, withObject: object) { (object, value) throws -> Result<ResultType> in
            let result = try onFulfilled(object, value)
            
            return .Defer(result)
        }
    }
    
    public func handleOn(dispatcher: Dispatcher, _ onRejected: (ErrorType) throws -> Result<ValueType>) -> Promise<ValueType> {
        return thenOn(
            dispatcher,
            onFulfilled: { (value) throws -> Result<ValueType> in
                return .Value(value)
            },
            onRejected: { (reason) throws -> Result<ValueType> in
                let result = try onRejected(reason)
                
                return result
            }
        )
    }
    
    public func handleOn(dispatcher: Dispatcher, _ onRejected: (ErrorType) throws -> Void) -> Promise<ValueType> {
        return handleOn(dispatcher) { (reason) throws -> Result<ValueType> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handleOn(dispatcher: Dispatcher, _ onRejected: (ErrorType) throws -> ValueType) -> Promise<ValueType> {
        return handleOn(dispatcher) { (reason) throws -> Result<ValueType> in
            let result = try onRejected(reason)
            
            return .Value(result)
        }
    }
    
    public func handleOn(dispatcher: Dispatcher, _ onRejected: (ErrorType) throws -> Promise<ValueType>) -> Promise<ValueType> {
        return handleOn(dispatcher) { (reason) throws -> Result<ValueType> in
            let result = try onRejected(reason)
            
            return .Defer(result)
        }
    }
    
    public func handleOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onRejected: (Object, ErrorType) throws -> Result<ValueType>) -> Promise<ValueType> {
        return handleOn(dispatcher) { [weak object] (reason) -> Result<ValueType> in
            guard let object = object else { throw PromiseError.ObjectUnavailable }
            
            let result = try onRejected(object, reason)
            
            return result
        }
    }
    
    public func handleOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onRejected: (Object, ErrorType) throws -> Void) -> Promise<ValueType> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<ValueType> in
            try onRejected(object, reason)
            
            throw reason
        }
    }
    
    public func handleOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onRejected: (Object, ErrorType) throws -> ValueType) -> Promise<ValueType> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<ValueType> in
            let result = try onRejected(object, reason)
            
            return .Value(result)
        }
    }
    
    public func handleOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onRejected: (Object, ErrorType) throws -> Promise<ValueType>) -> Promise<ValueType> {
        return handleOn(dispatcher, withObject: object) { (object, reason) throws -> Result<ValueType> in
            let result = try onRejected(object, reason)
            
            return .Defer(result)
        }
    }
    
    public func finallyOn(dispatcher: Dispatcher, _ onFinally: () -> Void) -> Promise<ValueType> {
        return thenOn(
            dispatcher,
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
    
    public func finallyOn<Object: AnyObject>(dispatcher: Dispatcher, withObject object: Object, _ onFinally: (Object) -> Void) -> Promise<ValueType> {
        return finallyOn(dispatcher) { [weak object] in
            guard let object = object else { return }
            
            onFinally(object)
        }
    }
}
