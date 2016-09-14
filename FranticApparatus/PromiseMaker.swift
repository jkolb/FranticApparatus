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

public final class PromiseMaker<Context: AnyObject, Value> {
    public static func makeUsing<InitialValue>(dispatcher: Dispatcher, context: Context, builder: (((Context) -> Promise<InitialValue>) -> PromiseMaker<Context, InitialValue>) -> PromiseMaker<Context, Value>) -> Promise<Value> {
        return builder { (initialBuilder) in
            return PromiseMaker<Context, InitialValue>(dispatcher: dispatcher, context: context, promise: initialBuilder(context))
        }.promise
    }
    
    fileprivate let dispatcher: Dispatcher
    fileprivate let context: Context
    fileprivate let promise: Promise<Value>
    
    fileprivate init(dispatcher: Dispatcher, context: Context, promise: Promise<Value>) {
        self.dispatcher = dispatcher
        self.context = context
        self.promise = promise
    }
    
    fileprivate func thenOn<ResultingValue>(_ dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> Promise<ResultingValue> {
        return promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    fileprivate func then<ResultingValue>(onFulfilled: @escaping (Value) throws -> Result<ResultingValue>, onRejected: @escaping (Error) throws -> Result<ResultingValue>) -> PromiseMaker<Context, ResultingValue> {
        let promise2 = promise.thenOn(dispatcher, onFulfilled: onFulfilled, onRejected: onRejected)
        return PromiseMaker<Context, ResultingValue>(dispatcher: dispatcher, context: context, promise: promise2)
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> Result<ResultingValue>) -> PromiseMaker<Context, ResultingValue> {
        weak var context = self.context
        
        return then(
            onFulfilled: { (value) throws -> Result<ResultingValue> in
                guard let context = context else { throw PromiseError.contextDeallocated }
                
                return try onFulfilled(context, value)
            },
            onRejected: { (reason) throws -> Result<ResultingValue> in
                throw reason
            }
        )
    }
    
    public func then(_ onFulfilled: @escaping (Context, Value) throws -> Void) -> PromiseMaker<Context, Value> {
        return then { (context, value) throws -> Result<Value> in
            try onFulfilled(context, value)
            
            return .value(value)
        }
    }
    
    public func then<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> ResultingValue) -> PromiseMaker<Context, ResultingValue> {
        return then { (context, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(context, value)
            
            return .value(result)
        }
    }

    public func then<ResultingValue>(_ onFulfilled: @escaping (Context, Value) throws -> Promise<ResultingValue>) -> PromiseMaker<Context, ResultingValue> {
        return then { (context, value) throws -> Result<ResultingValue> in
            let result = try onFulfilled(context, value)
            
            return .promise(result)
        }
    }
    
    fileprivate func handle(_ onRejected: @escaping (Error) throws -> Result<Value>) -> PromiseMaker<Context, Value> {
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
    
    public func handle(_ onRejected: @escaping (Error) throws -> Void) -> PromiseMaker<Context, Value> {
        return handle { (reason) throws -> Result<Value> in
            try onRejected(reason)
            
            throw reason
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Value) -> PromiseMaker<Context, Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .value(result)
        }
    }
    
    public func handle(_ onRejected: @escaping (Error) throws -> Promise<Value>) -> PromiseMaker<Context, Value> {
        return handle { (reason) throws -> Result<Value> in
            let result = try onRejected(reason)
            
            return .promise(result)
        }
    }
    
    public func finally(_ onFinally: @escaping () -> Void) -> PromiseMaker<Context, Value> {
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
