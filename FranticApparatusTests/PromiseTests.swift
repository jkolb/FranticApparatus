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

import XCTest
@testable import FranticApparatus

enum TestError : Int, ErrorType, Equatable {
    case ExpectedRejection = 1
    case UnexpectedRejection = 2
}

class FranticApparatusTests: XCTestCase, Dispatcher {
    var promiseIntA: Promise<Int>!
    var promiseIntB: Promise<Int>!
    var promiseString: Promise<String>!
    var pendingDispatch: [() -> Void]!
    
    override func setUp() {
        super.setUp()
        
        promiseIntA = nil
        promiseIntB = nil
        promiseString = nil
        pendingDispatch = []
    }
    
    func testFulfill() {
        var promisedValue = 0
        
        promiseIntA = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                promisedValue = value
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                throw reason
            }
        )
        
        dispatchNext()
        
        XCTAssertEqual(promisedValue, 1)
    }
    
    func testReject() {
        var promisedReason = TestError.UnexpectedRejection
        
        promiseIntA = Promise<Int> { (fulfill, reject, isCancelled) in reject(TestError.ExpectedRejection) }.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                promisedReason = reason as! TestError
                throw reason
            }
        )
        
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.ExpectedRejection)
    }
    
    func testThenMayBeCalledMultipleTimesOnTheSamePromiseAndFulfilledInOrder() {
        var promisedOrders = [Int]()
        var promisedOrder = 0
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> Void in fulfill(1) }
        
        promiseIntA = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                throw reason
            }
        )

        promiseIntB = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                throw reason
            }
        )

        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual([1, 2], promisedOrders)
    }
    
    func testThenMayBeCalledMultipleTimesOnTheSamePromiseAndRejectedInOrder() {
        var promisedOrders = [Int]()
        var promisedOrder = 0
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> Void in reject(TestError.ExpectedRejection) }
        
        promiseIntA = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                throw reason
            }
        )
        
        promiseIntB = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<Int> in
                return .Value(value)
            },
            onRejected: { (reason) -> Result<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                throw reason
            }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual([1, 2], promisedOrders)
    }
    
    func testWhenPromiseResolvedWithAPromiseThenPromise2WillFulfillWithValueOfThatPromise() {
        var promisedValue = ""
        
        let promiseA = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }
        let promiseB = Promise<String> { (fulfill, reject, isCancelled) in fulfill("promised") }
        
        promiseString = promiseA.thenOn(
            self,
            onFulfilled: { (value) -> Result<String> in
                return .Defer(promiseB)
            },
            onRejected: { (reason) -> Result<String> in
                throw reason
            }
            ).thenOn(
                self,
                onFulfilled: { (value) -> Result<String> in
                    promisedValue = value
                    return .Value(value)
                },
                onRejected: { (reason) -> Result<String> in
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedValue, "promised")
    }
    
    func testWhenPromiseResolvedWithAPromiseThenPromise2WillRejectWithReasonOfThatPromise() {
        var promisedReason = TestError.UnexpectedRejection
        
        let promiseA = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }
        let promiseB = Promise<String> { (fulfill, reject, isCancelled) in reject(TestError.ExpectedRejection) }
        
        promiseString = promiseA.thenOn(
            self,
            onFulfilled: { (value) -> Result<String> in
                return .Defer(promiseB)
            },
            onRejected: { (reason) -> Result<String> in
                throw reason
            }
            ).thenOn(
                self,
                onFulfilled: { (value) -> Result<String> in
                    return .Value(value)
                },
                onRejected: { (reason) -> Result<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.ExpectedRejection)
    }
    
    func testPromise1OnFulfilledThrowsErrorPromise2MustBeRejectedWithSameReason() {
        var promisedReason = TestError.UnexpectedRejection
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }
        
        promiseString = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<String> in
                throw TestError.ExpectedRejection
            },
            onRejected: { (reason) -> Result<String> in
                throw reason
            }
            ).thenOn(
                self,
                onFulfilled: { (value) -> Result<String> in
                    return .Value(value)
                },
                onRejected: { (reason) -> Result<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.ExpectedRejection)
    }
    
    func testPromise1OnRejectedThrowsErrorPromise2MustBeRejectedWithSameReason() {
        var promisedReason = TestError.UnexpectedRejection
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in reject(TestError.UnexpectedRejection) }
        
        promiseString = promise.thenOn(
            self,
            onFulfilled: { (value) -> Result<String> in
                return .Value("promised")
            },
            onRejected: { (reason) -> Result<String> in
                throw TestError.ExpectedRejection
            }
            ).thenOn(
                self,
                onFulfilled: { (value) -> Result<String> in
                    return .Value(value)
                },
                onRejected: { (reason) -> Result<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.ExpectedRejection)
    }

    func dispatch(closure: () -> Void) {
        pendingDispatch.append(closure)
    }
    
    func dispatchNext() {
        let closure = pendingDispatch.removeFirst()
        closure()
    }
}
