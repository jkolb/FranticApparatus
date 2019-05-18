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

public final class PromiseMaker {
    public static func makeUsing<Context, Value, InitialValue>(dispatcher: Dispatcher = GCDDispatcher.main, context: Context, builder: (((Context) -> Promise<InitialValue>) -> PromiseMakerHelper<Context, InitialValue>) -> PromiseMakerHelper<Context, Value>) -> Promise<Value> {
        return builder { (initialBuilder) in
            return PromiseMakerHelper<Context, InitialValue>(dispatcher: dispatcher, context: context, promise: initialBuilder(context))
        }.promise
    }
}

public final class PromiseMakerHelper<Context: AnyObject, Value> {
    private let dispatcher: Dispatcher
    private let context: Context
    fileprivate let promise: Promise<Value>
    
    fileprivate init(dispatcher: Dispatcher, context: Context, promise: Promise<Value>) {
        self.dispatcher = dispatcher
        self.context = context
        self.promise = promise
    }
    
    public func then<ResultingValue>(onFulfilled: @escaping (Context, Value) throws -> Promised<ResultingValue>, onRejected: @escaping (Context, Error) throws -> Promised<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        weak var weakContext = self.context

        let promise2 = promise.then(
            on: dispatcher,
            onFulfilled: { (value) throws -> Promised<ResultingValue> in
                guard let context = weakContext else { throw PromiseError.contextDeallocated }
                
                return try onFulfilled(context, value)
            },
            onRejected: { (reason) throws -> Promised<ResultingValue> in
                guard let context = weakContext else { throw PromiseError.contextDeallocated }
                
                return try onRejected(context, reason)
            }
        )
        return PromiseMakerHelper<Context, ResultingValue>(dispatcher: dispatcher, context: context, promise: promise2)
    }
    
    public func whenFulfilledThenMap<ResultingValue>(_ map: @escaping (Context, Value) throws -> Promised<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        return then(
            onFulfilled: { (context, value) throws -> Promised<ResultingValue> in
                return try map(context, value)
            },
            onRejected: { (context, reason) throws -> Promised<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func whenFulfilled(_ thenDo: @escaping (Context, Value) throws -> Void) -> PromiseMakerHelper<Context, Value> {
        return whenFulfilledThenMap { (context, value) throws -> Promised<Value> in
            try thenDo(context, value)
            
            return .value(value)
        }
    }
    
    public func whenFulfilledThenTransform<ResultingValue>(_ transform: @escaping (Context, Value) throws -> ResultingValue) -> PromiseMakerHelper<Context, ResultingValue> {
        return whenFulfilledThenMap { (context, value) throws -> Promised<ResultingValue> in
            let result = try transform(context, value)
            
            return .value(result)
        }
    }
    
    public func whenFulfilledThenPromise<ResultingValue>(_ promise: @escaping (Context, Value) throws -> Promise<ResultingValue>) -> PromiseMakerHelper<Context, ResultingValue> {
        return whenFulfilledThenMap { (context, value) throws -> Promised<ResultingValue> in
            let result = try promise(context, value)
            
            return .promise(result)
        }
    }
    
    public func whenRejectedThenMap(_ map: @escaping (Context, Error) throws -> Promised<Value>) -> PromiseMakerHelper<Context, Value> {
        return then(
            onFulfilled: { (context, value) throws -> Promised<Value> in
                return .value(value)
            },
            onRejected: { (context, reason) throws -> Promised<Value> in
                let result = try map(context, reason)
                
                return result
            }
        )
    }
    
    public func whenRejected(_ thenDo: @escaping (Context, Error) throws -> Void) -> PromiseMakerHelper<Context, Value> {
        return whenRejectedThenMap { (context, reason) throws -> Promised<Value> in
            try thenDo(context, reason)
            
            throw reason
        }
    }
    
    public func whenRejectedThenTransform(_ transform: @escaping (Context, Error) throws -> Value) -> PromiseMakerHelper<Context, Value> {
        return whenRejectedThenMap { (context, reason) throws -> Promised<Value> in
            let result = try transform(context, reason)
            
            return .value(result)
        }
    }
    
    public func whenRejectedThenPromise(_ promise: @escaping (Context, Error) throws -> Promise<Value>) -> PromiseMakerHelper<Context, Value> {
        return whenRejectedThenMap { (context, reason) throws -> Promised<Value> in
            let result = try promise(context, reason)
            
            return .promise(result)
        }
    }
    
    public func whenComplete(_ thenDo: @escaping (Context) -> Void) -> PromiseMakerHelper<Context, Value> {
        return then(
            onFulfilled: { (context, value) throws -> Promised<Value> in
                thenDo(context)
                
                return .value(value)
            },
            onRejected: { (context, reason) throws -> Promised<Value> in
                thenDo(context)
                
                throw reason
            }
        )
    }
}
