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
    
    func then<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> Promise<ResultingValue>
}

public extension Thenable {
    public func then<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func then(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Void) -> Promise<Value> {
        return then(on: dispatcher) { (value) throws -> Result<Value> in
            try onFulfilled(value)
            
            return .value(value)
        }
    }
    
    public func thenTransform<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> ResultingValue) -> Promise<ResultingValue> {
        return then(on: dispatcher) { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .value(result)
        }
    }
    
    public func thenPromise<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Promise<ResultingValue>) -> Promise<ResultingValue> {
        return then(on: dispatcher) { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .promise(result)
        }
    }
    
    public func handle(on dispatcher: Dispatcher, onRejected: @escaping (Error) throws -> Result<Value>) -> Promise<Value> {
        return then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Result<Value> in
                return .value(value)
            },
            onRejected: { (reason) throws -> Result<Value> in
                let result = try onRejected(reason)
                
                return result
            }
        )
    }
    
    public func handle(on dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Void) -> Promise<Value> {
        return handle(on: dispatcher) { (reason) throws -> Result<Value> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handle(on dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Value) -> Promise<Value> {
        return handle(on: dispatcher) { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .value(result)
        }
    }
    
    public func handle(on dispatcher: Dispatcher, _ onRejected: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return handle(on: dispatcher) { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .promise(result)
        }
    }
    
    public func finally(on dispatcher: Dispatcher, _ onFinally: @escaping () -> Void) -> Promise<Value> {
        return then(
            on: dispatcher,
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
}
