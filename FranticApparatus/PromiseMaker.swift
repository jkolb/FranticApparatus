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

public final class PromiseMaker {
    public static func makeUsing<Context, Value, InitialValue>(dispatcher: Dispatcher, context: Context, builder: (((Context) -> Promise<InitialValue>) -> PromiseMakerHelper<Context, InitialValue>) -> PromiseMakerHelper<Context, Value>) -> Promise<Value> {
        return builder { (initialBuilder) in
            return PromiseMakerHelper<Context, InitialValue>(dispatcher: dispatcher, context: context, promise: initialBuilder(context))
        }.promise
    }
}

public final class PromiseMakerHelper<Context: AnyObject, Value> {
    fileprivate let dispatcher: Dispatcher
    fileprivate let context: Context
    fileprivate let promise: Promise<Value>
    
    fileprivate init(dispatcher: Dispatcher, context: Context, promise: Promise<Value>) {
        self.dispatcher = dispatcher
        self.context = context
        self.promise = promise
    }
    
    public func then<ResultingValue>(onFulfilled: @escaping (Context, Value) throws -> Result<ResultingValue>, onRejected: @escaping (Context, Error) throws -> Result<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        weak var weakContext = self.context

        let promise2 = promise.then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                guard let context = weakContext else { throw PromiseError.contextDeallocated }
                
                return try onFulfilled(context, value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                guard let context = weakContext else { throw PromiseError.contextDeallocated }
                
                return try onRejected(context, reason)
            }
        )
        return PromiseMakerHelper<Context, ResultingValue>(dispatcher: dispatcher, context: context, promise: promise2)
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> Result<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        return then(
            onFulfilled: { (context, value) throws -> Result<ResultingValue> in
                return try onFulfilled(context, value)
            },
            onRejected: { (context, reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func then(_ onFulfilled: @escaping (Context, Value) throws -> Void) -> PromiseMakerHelper<Context, Value> {
        return then { (context, value) throws -> Result<Value> in
            try onFulfilled(context, value)
            
            return .value(value)
        }
    }
    
    public func thenTransform<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> ResultingValue) -> PromiseMakerHelper<Context, ResultingValue> {
        return then { (context, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(context, value)
            
            return .value(result)
        }
    }
    
    public func thenPromise<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> Promise<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        return then { (context, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(context, value)
            
            return .promise(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Context, Error) throws -> Result<Value>) -> PromiseMakerHelper<Context, Value> {
        return then(
            onFulfilled: { (context, value) throws -> Result<Value> in
                return .value(value)
            },
            onRejected: { (context, reason) throws -> Result<Value> in
                let result = try onRejected(context, reason)
                
                return result
            }
        )
    }
    
    public func `catch`(_ onRejected: @escaping (Context, Error) throws -> Void) -> PromiseMakerHelper<Context, Value> {
        return handle { (context, reason) throws -> Result<Value> in
            try onRejected(context, reason)
            
            throw reason
        }
    }
    
    public func handle(_ onRejected: @escaping (Context, Error) throws -> Value) -> PromiseMakerHelper<Context, Value> {
        return handle { (context, reason) throws -> Result<Value> in
            let result = try onRejected(context, reason)
            
            return .value(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Context, Error) throws -> Promise<Value>) -> PromiseMakerHelper<Context, Value> {
        return handle { (context, reason) throws -> Result<Value> in
            let result = try onRejected(context, reason)
            
            return .promise(result)
        }
    }
    
    public func finally(_ onFinally: @escaping (Context) -> Void) -> PromiseMakerHelper<Context, Value> {
        return then(
            onFulfilled: { (context, value) throws -> Result<Value> in
                onFinally(context)
                
                return .value(value)
            },
            onRejected: { (context, reason) throws -> Result<Value> in
                onFinally(context)
                
                throw reason
            }
        )
    }
}
