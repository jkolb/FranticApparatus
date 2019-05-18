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

enum TestError : Int, Error, Equatable {
    case expectedRejection = 1
    case unexpectedRejection = 2
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
        
        promiseIntA = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                promisedValue = value
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
                throw reason
            }
        )
        
        dispatchNext()
        
        XCTAssertEqual(promisedValue, 1)
    }
    
    func testReject() {
        var promisedReason = TestError.unexpectedRejection
        
        promiseIntA = Promise<Int> { (fulfill, reject, isCancelled) in reject(TestError.expectedRejection) }.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
                promisedReason = reason as! TestError
                throw reason
            }
        )
        
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.expectedRejection)
    }
    
    func testThenMayBeCalledMultipleTimesOnTheSamePromiseAndFulfilledInOrder() {
        var promisedOrders = [Int]()
        var promisedOrder = 0
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> Void in fulfill(1) }
        
        promiseIntA = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
                throw reason
            }
        )

        promiseIntB = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
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
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> Void in reject(TestError.expectedRejection) }
        
        promiseIntA = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
                promisedOrder += 1
                promisedOrders.append(promisedOrder)
                throw reason
            }
        )
        
        promiseIntB = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<Int> in
                return .value(value)
            },
            onRejected: { (reason) -> Promised<Int> in
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
        
        promiseString = promiseA.then(
            on: self,
            onFulfilled: { (value) -> Promised<String> in
                return .promise(promiseB)
            },
            onRejected: { (reason) -> Promised<String> in
                throw reason
            }
            ).then(
                on: self,
                onFulfilled: { (value) -> Promised<String> in
                    promisedValue = value
                    return .value(value)
                },
                onRejected: { (reason) -> Promised<String> in
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedValue, "promised")
    }
    
    func testWhenPromiseResolvedWithAPromiseThenPromise2WillRejectWithReasonOfThatPromise() {
        var promisedReason = TestError.unexpectedRejection
        
        let promiseA = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }
        let promiseB = Promise<String> { (fulfill, reject, isCancelled) in reject(TestError.expectedRejection) }
        
        promiseString = promiseA.then(
            on: self,
            onFulfilled: { (value) -> Promised<String> in
                return .promise(promiseB)
            },
            onRejected: { (reason) -> Promised<String> in
                throw reason
            }
            ).then(
                on: self,
                onFulfilled: { (value) -> Promised<String> in
                    return .value(value)
                },
                onRejected: { (reason) -> Promised<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.expectedRejection)
    }
    
    func testPromise1OnFulfilledThrowsErrorPromise2MustBeRejectedWithSameReason() {
        var promisedReason = TestError.unexpectedRejection
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in fulfill(1) }
        
        promiseString = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<String> in
                throw TestError.expectedRejection
            },
            onRejected: { (reason) -> Promised<String> in
                throw reason
            }
            ).then(
                on: self,
                onFulfilled: { (value) -> Promised<String> in
                    return .value(value)
                },
                onRejected: { (reason) -> Promised<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.expectedRejection)
    }
    
    func testPromise1OnRejectedThrowsErrorPromise2MustBeRejectedWithSameReason() {
        var promisedReason = TestError.unexpectedRejection
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in reject(TestError.unexpectedRejection) }
        
        promiseString = promise.then(
            on: self,
            onFulfilled: { (value) -> Promised<String> in
                return .value("promised")
            },
            onRejected: { (reason) -> Promised<String> in
                throw TestError.expectedRejection
            }
            ).then(
                on: self,
                onFulfilled: { (value) -> Promised<String> in
                    return .value(value)
                },
                onRejected: { (reason) -> Promised<String> in
                    promisedReason = reason as! TestError
                    throw reason
                }
        )
        
        dispatchNext()
        dispatchNext()
        
        XCTAssertEqual(promisedReason, TestError.expectedRejection)
    }

    func async(_ closure: @escaping () -> Void) {
        pendingDispatch.append(closure)
    }
    
    func dispatchNext() {
        let closure = pendingDispatch.removeFirst()
        closure()
    }

    static var allTests = [
        ("testFulfill", testFulfill),
        ("testReject", testReject),
        ("testThenMayBeCalledMultipleTimesOnTheSamePromiseAndFulfilledInOrder", testThenMayBeCalledMultipleTimesOnTheSamePromiseAndFulfilledInOrder),
        ("testThenMayBeCalledMultipleTimesOnTheSamePromiseAndRejectedInOrder", testThenMayBeCalledMultipleTimesOnTheSamePromiseAndRejectedInOrder),
        ("testWhenPromiseResolvedWithAPromiseThenPromise2WillFulfillWithValueOfThatPromise", testWhenPromiseResolvedWithAPromiseThenPromise2WillFulfillWithValueOfThatPromise),
        ("testWhenPromiseResolvedWithAPromiseThenPromise2WillRejectWithReasonOfThatPromise", testWhenPromiseResolvedWithAPromiseThenPromise2WillRejectWithReasonOfThatPromise),
        ("testPromise1OnFulfilledThrowsErrorPromise2MustBeRejectedWithSameReason", testPromise1OnFulfilledThrowsErrorPromise2MustBeRejectedWithSameReason),
        ("testPromise1OnRejectedThrowsErrorPromise2MustBeRejectedWithSameReason", testPromise1OnRejectedThrowsErrorPromise2MustBeRejectedWithSameReason),
    ]
}
