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

public final class PromiseMaker<Value> {
    // Now I am become Death, the destroyer of worlds.
    public static func makeUsing<InitialValue>(dispatcher: Dispatcher, builder: ((() -> Promise<InitialValue>) -> PromiseMaker<InitialValue>) -> PromiseMaker<Value>) -> Promise<Value> {
        return builder { (initialBuilder) in
            return PromiseMaker<InitialValue>(dispatcher: dispatcher, promise: initialBuilder())
        }.promise
    }
    
    public let dispatcher: Dispatcher
    public let promise: Promise<Value>
    
    public init(dispatcher: Dispatcher, promise: Promise<Value>) {
        self.dispatcher = dispatcher
        self.promise = promise
    }
    
    fileprivate func thenOn<ResultingValue>(_ dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    fileprivate func then<ResultingValue>(onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> PromiseMaker<ResultingValue> {
        let promise2 = promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
        return PromiseMaker<ResultingValue>(dispatcher: dispatcher, promise: promise2)
    }
    
    fileprivate func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> Result<ResultingValue>) -> PromiseMaker<ResultingValue> {
        return then(
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                return try onFulfilled(value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func then(_ onFulfilled: @escaping (Value) throws -> Void) -> PromiseMaker<Value> {
        return then { (value) throws -> Result<Value> in
            try onFulfilled(value)
            
            return .value(value)
        }
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> ResultingValue) -> PromiseMaker<ResultingValue> {
        return then { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .value(result)
        }
    }

    public func then<ResultingValue>(_ onFulfilled: @escaping (Value) throws -> Promise<ResultingValue>) -> PromiseMaker<ResultingValue> {
        return then { (value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(value)
            
            return .promise(result)
        }
    }
    
    fileprivate func handle(_ onRejected: @escaping (Error) throws -> Result<Value>) -> PromiseMaker<Value> {
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
    
    public func handle(_ onRejected: @escaping (Error) throws -> Void) -> PromiseMaker<Value> {
        return handle { (reason) throws -> Result<Value> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Value) -> PromiseMaker<Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .value(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Promise<Value>) -> PromiseMaker<Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .promise(result)
        }
    }
    
    public func finally(_ onFinally: @escaping () -> Void) -> PromiseMaker<Value> {
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
}
