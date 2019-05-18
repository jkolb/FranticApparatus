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

public protocol Thenable : class {
    associatedtype Value
    
    func then<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Fulfilled<ResultingValue>, onRejected: @escaping (Error) throws -> Fulfilled<ResultingValue>) -> Promise<ResultingValue>
}

public extension Thenable {
    func whenFulfilledThenMap<ResultingValue>(on dispatcher: Dispatcher, map: @escaping (Value) throws -> Fulfilled<ResultingValue>) -> Promise<ResultingValue> {
        return then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Fulfilled<ResultingValue> in
                return try map(value)
            },
            onRejected: { (reason) throws -> Fulfilled<ResultingValue> in
                throw reason
            }
        )
    }
    
    func whenFulfilled(on dispatcher: Dispatcher, thenDo: @escaping (Value) throws -> Void) -> Promise<Value> {
        return whenFulfilledThenMap(on: dispatcher) { (value) throws -> Fulfilled<Value> in
            try thenDo(value)
            
            return .value(value)
        }
    }
    
    func whenFulfilledThenTransform<ResultingValue>(on dispatcher: Dispatcher, transform: @escaping (Value) throws -> ResultingValue) -> Promise<ResultingValue> {
        return whenFulfilledThenMap(on: dispatcher) { (value) throws -> Fulfilled<ResultingValue> in
            let result = try transform(value)
            
            return .value(result)
        }
    }
    
    func whenFulfilledThenPromise<ResultingValue>(on dispatcher: Dispatcher, promise: @escaping (Value) throws -> Promise<ResultingValue>) -> Promise<ResultingValue> {
        return whenFulfilledThenMap(on: dispatcher) { (value) throws -> Fulfilled<ResultingValue> in
            let result = try promise(value)
            
            return .promise(result)
        }
    }
    
    func whenRejectedThenMap(on dispatcher: Dispatcher, map: @escaping (Error) throws -> Fulfilled<Value>) -> Promise<Value> {
        return then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Fulfilled<Value> in
                return .value(value)
            },
            onRejected: { (reason) throws -> Fulfilled<Value> in
                let result = try map(reason)
                
                return result
            }
        )
    }
    
    func whenRejected(on dispatcher: Dispatcher, thenDo: @escaping (Error) throws -> Void) -> Promise<Value> {
        return whenRejectedThenMap(on: dispatcher) { (reason) throws -> Fulfilled<Value> in
            try thenDo(reason)
            
            throw reason
        }
    }
    
    func whenRejectedThenTransform(on dispatcher: Dispatcher, transform: @escaping (Error) throws -> Value) -> Promise<Value> {
        return whenRejectedThenMap(on: dispatcher) { (reason) throws -> Fulfilled<Value> in
            let result = try transform(reason)
            
            return .value(result)
        }
    }
    
    func whenRejectedThenPromise(on dispatcher: Dispatcher, promise: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return whenRejectedThenMap(on: dispatcher) { (reason) throws -> Fulfilled<Value> in
            let result = try promise(reason)
            
            return .promise(result)
        }
    }
    
    func whenComplete(on dispatcher: Dispatcher, thenDo: @escaping () -> Void) -> Promise<Value> {
        return then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Fulfilled<Value> in
                thenDo()
                
                return .value(value)
            },
            onRejected: { (reason) throws -> Fulfilled<Value> in
                thenDo()
                
                throw reason
            }
        )
    }
}
