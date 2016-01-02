// Copyright (c) 2016 Justin Kolb - http://franticapparatus.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
@testable import FranticApparatus

enum TestError : ErrorType {
    case ExpectedRejection
    case UnexpectedRejection
}

class FranticApparatusTests: XCTestCase {
    
    // 2.1.1 - When pending, a promise:
    // 2.1.1.1 - may transition to either the fulfilled or rejected state
    
    var waitForPromiseA: Promise<Int>! = nil
    var waitForPromiseB: Promise<Int>! = nil
    
    var waitForPromiseY: Promise<String>! = nil
    var waitForPromiseZ: Promise<String>! = nil
    
    func testWhenPendingIsFulfilledTransitionsToFulfilledState() {
        let expectation = self.expectationWithDescription("onFulfilled called")
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
            fulfill(1)
        }
        
        var isFulfilled = false
        
        waitForPromiseA = promise.thenWithContext(self) { (strongSelf, value) -> Void in
            isFulfilled = true
            strongSelf.waitForPromiseA = nil
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(isFulfilled, "When pending, a promise may transition to the fulfilled state")
        }
    }
    
    func testWhenPendingIsRejectedTransitionsToRejectedState() {
        let expectation = self.expectationWithDescription("onRejected called")
        
        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
            reject(TestError.ExpectedRejection)
        }
        
        var isRejected = false
        
        waitForPromiseA = promise.handleWithContext(self) { (strongSelf, error) in
            isRejected = true
            strongSelf.waitForPromiseA = nil
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(isRejected, "When pending, a promise may transition to the rejected state")
        }
    }
    
    // 2.1.2 - When fulfilled, a promise:
    // 2.1.2.1 - must not transition to any other state
    
//    func testFulfilledMustNotTranstionToAnyOtherState() {
//        let promiseFulfilled1 = self.expectationWithDescription("onFulfilled called once")
//        
//        let promiseFulfilled2 = self.expectationWithDescription("onFulfilled called twice")
//        
//        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
//            fulfill(1)
//            reject(TestError.ExpectedRejection)
//        }
//        
//        var isFulfilled = false
//        
//        waitForPromiseA = promise.thenWithContext(self) { (strongSelf, value) in
//            isFulfilled = true
//            strongSelf.waitForPromiseA = nil
//            promiseFulfilled1.fulfill()
//        }
//        
//        waitForPromiseB = promise.then(
//            onFulfilled: { (value) -> Int in
//                isFulfilled = true
//                return value
//            },
//            onRejected: { (reason) -> Int in
//                isFulfilled = false
//                throw reason
//            }
//        ).finallyWithContext(self, { strongSelf in
//            strongSelf.waitForPromiseB = nil
//            promiseFulfilled2.fulfill()
//        })
//        
//        self.waitForExpectationsWithTimeout(1.0) { error in
//            XCTAssertTrue(isFulfilled, "When fulfilled, a promise must not transition to any other state")
//        }
//    }
    
    // 2.1.2.2 - must have a value, which must not change
    
//    func testFulfilledMustHaveAValueWhichMustNotChange() {
//        let promiseFulfilled1 = self.expectationWithDescription("onFulfilled called once")
//        
//        let promiseFulfilled2 = self.expectationWithDescription("onFulfilled called twice")
//        
//        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
//            fulfill(1)
//            fulfill(2)
//        }
//        
//        var fulfilledValue = 0
//        
//        waitForPromiseA = promise.thenWithContext(self) { (strongSelf, value) in
//            fulfilledValue = value
//            strongSelf.waitForPromiseA = nil
//            promiseFulfilled1.fulfill()
//        }
//        
//        waitForPromiseB = promise.thenWithContext(self) { (strongSelf, value) in
//            fulfilledValue = value
//            strongSelf.waitForPromiseB = nil
//            promiseFulfilled2.fulfill()
//        }
//        
//        self.waitForExpectationsWithTimeout(1.0) { error in
//            XCTAssertEqual(fulfilledValue, 1, "When fulfilled, a promise must have a value, which must not change")
//        }
//    }
    
    // 2.1.3 - When rejected, a promise
    // 2.1.3.1 - must not transition to any other state
    
//    func testRejectedMustNotTransitionToAnyOtherState() {
//        let promiseRejected1 = self.expectationWithDescription("onRejected called once")
//        
//        let promiseRejected2 = self.expectationWithDescription("onRejected called twice")
//        
//        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
//            reject(TestError.ExpectedRejection)
//            fulfill(1)
//        }
//        
//        var isRejected = false
//        
//        waitForPromiseA = promise.handleWithContext(self) { (strongSelf, error) in
//            isRejected = true
//            promiseRejected1.fulfill()
//            strongSelf.waitForPromiseA = nil
//        }
//        
//        waitForPromiseB = promise.then(
//            onFulfilled: { (value) -> Int in
//                isRejected = false
//                return value
//            },
//            onRejected: { (reason) -> Int in
//                isRejected = true
//                throw reason
//            }
//        ).finallyWithContext(self, { strongSelf in
//            strongSelf.waitForPromiseB = nil
//            promiseRejected2.fulfill()
//        })
//        
//        self.waitForExpectationsWithTimeout(1.0) { error in
//            XCTAssertTrue(isRejected, "When rejected, a promise must not transtion to any other state")
//        }
//    }
    
    // 2.1.3.2 - must have a reason, which must not change
    
//    func testRejectedMustHaveAReasonWhichMustNotChange() {
//        let promiseRejected1 = self.expectationWithDescription("onRejected called once")
//        
//        let promiseRejected2 = self.expectationWithDescription("onRejected called twice")
//        
//        let promise = Promise<Int> { (fulfill, reject, isCancelled) in
//            reject(TestError.ExpectedRejection)
//            reject(TestError.UnexpectedRejection)
//        }
//        
//        var rejectedReason: ErrorType = TestError.UnexpectedRejection
//        
//        waitForPromiseA = promise.handleWithContext(self) { (strongSelf, error) in
//            rejectedReason = error
//            strongSelf.waitForPromiseA = nil
//            promiseRejected1.fulfill()
//        }
//        
//        waitForPromiseB = promise.handleWithContext(self) { (strongSelf, error) in
//            rejectedReason = error
//            strongSelf.waitForPromiseB = nil
//            promiseRejected2.fulfill()
//        }
//        
//        self.waitForExpectationsWithTimeout(1.0) { error in
//            XCTAssertTrue(rejectedReason as? TestError == TestError.ExpectedRejection, "When rejected, a promise must have a reason, which must not change")
//        }
//    }
    
    // 2.2.1.1 - If onFulfilled is not a function, it must be ignored
    // 2.2.1.2 - If onRejected is not a function, it must be ignored
    //      **** Only closures are supported, non-closure values are unable to be supplied due to
    //      **** swift type checking. When used optionally (such as in the catch and when methods)
    //      **** a pass through version is automatically supplied instead of making the closure
    //      **** optional.
    
    // 2.2.2 - If onFulfilled is a function
    // 2.2.2.1 - it must be called after promise is fulfilled, with promise's value as its first argument
    
    func testOnFulfilledMustBeCalledAfterPromiseIsFulfilledWithThePromiseValueAsItsFirstArgument() {
        let expectation = self.expectationWithDescription("onFulfilled called")
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) in
            fulfill(1)
        }
        
        var receivedValue = 2
        
        waitForPromiseA = promise1.thenWithContext(self) { (strongSelf, value) -> Void in
            receivedValue = value
            strongSelf.waitForPromiseA = nil
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(receivedValue, 1, "If onFulfilled is a function it must be called after promise is fulfilled, with promise's value as its first argument")
        }
    }
    
    // 2.2.2.3 - it must not be called more than once
    
    // 2.2.3 - If onRejected is a function
    
    // 2.2.3.1 - it must be called after promise is rejected, with promise's reason as its first argument
    
    // 2.2.3.3 - it must not be called more than once
    
    // 2.2.4 - onFulfilled or onRejected must not be called until the execution context stack contains only platform code.
    
    // 2.2.5 - onFulfilled and onRejected must be called as functions (i.e. with no this value).
    
    // 2.2.6 - then may be called multiple times on the same promise
    
    func testThenMayBeCalledMultipleTimesOnTheSamePromise() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> Void in
            fulfill(1)
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        
        waitForPromiseY = promise1.then(
            onFulfilled: { (value) -> String in
                fulfilledToken.append(1)
                return ""
            },
            onRejected: { (reason) -> String in
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseY = nil
                callThenOnce.fulfill()
            })
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        
        waitForPromiseZ = promise1.then(
            onFulfilled: { (value) -> String in
                fulfilledToken.append(2)
                return ""
            },
            onRejected: { (reason) -> String in
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseZ = nil
                callThenTwice.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(fulfilledToken.count, 2, "then may be called multiple times on the same promise")
        }
    }
    
    // 2.2.6.1 - if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then
    
    func testOnFulfilledCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> Void in
            fulfill(1)
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        
        waitForPromiseY = promise1.then(
            onFulfilled: { (value) -> String in
                fulfilledToken.append(1)
                return ""
            },
            onRejected: { (reason) -> String in
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseY = nil
                callThenOnce.fulfill()
            })
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        
        waitForPromiseZ = promise1.then(
            onFulfilled: { (value) -> String in
                fulfilledToken.append(2)
                return ""
            }, onRejected: { (reason) -> String in
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseZ = nil
                callThenTwice.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(fulfilledToken[0], 1, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
            XCTAssertEqual(fulfilledToken[1], 2, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
        }
    }
    
    // 2.2.6.2 - if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then
    
    func testOnRejectedCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var rejectedToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> Void in
            reject(TestError.ExpectedRejection)
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        
        waitForPromiseY = promise1.then(
            onFulfilled: { value in
                return ""
            },
            onRejected: { reason in
                rejectedToken.append(1)
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseY = nil
                callThenOnce.fulfill()
            })
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        
        waitForPromiseZ = promise1.then(
            onFulfilled: { (value) -> String in
                return ""
            },
            onRejected: { (reason) -> String in
                rejectedToken.append(2)
                throw TestError.ExpectedRejection
            }
            ).finallyWithContext(self, { strongSelf in
                strongSelf.waitForPromiseZ = nil
                callThenTwice.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(rejectedToken[0], 1, "if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then")
            XCTAssertEqual(rejectedToken[1], 2, "if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then")
        }
    }
    
    // 2.2.7 - then must return a promise. promise2 = promise1.then(onFulfilled, onRejected)

    func testThenMustReturnAPromise() {
        let promise1  = Promise<Int> { (fulfill, reject, isCancelled) -> Void in
        }
        
        let promise2: Any = promise1.then(
            onFulfilled: { (value) -> String in
                return ""
            },
            onRejected: { (reason) -> String in
                throw TestError.ExpectedRejection
            })
        
        var thenReturnedPromise = false
        
        if promise2 is Promise<String> {
            thenReturnedPromise = true
        }
        
        XCTAssertTrue(thenReturnedPromise, "then must return a promise")
    }
    
    // 2.2.7.1 - If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).
    
    func testWhenPromise1OnFulfilledReturnsAnotherPromiseThenPromise2WillFulfillWithValueOfDeferred() {
        let expectation = self.expectationWithDescription("")
        
        let promise1  = Promise<Int> { (fulfill, reject, isCancelled) -> Void in
            fulfill(1)
        }
        
        let deferred = Promise<String>() { (fulfill, reject, isCancelled) -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                fulfill("deferred")
            }
        }
        
        var receivedValue: String! = nil
        
        waitForPromiseY = promise1.then(
            onFulfilled: { (value) -> Promise<String> in
                return deferred
            },
            onRejected: { (reason) -> Promise<String> in
                throw reason
            }
            ).thenWithContext(self, { (strongSelf, value) -> Void in
                receivedValue = value
                strongSelf.waitForPromiseY = nil
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(receivedValue, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
        }
    }
    
    func testWhenPromise1OnRejectedReturnsAnotherPromiseThenPromise2WillFulfillWithValueOfDeferred() {
        let expectation = self.expectationWithDescription("")
        
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> Void in
            reject(TestError.ExpectedRejection)
        }
        
        let deferred = Promise<String>() { (fulfill, reject, isCancelled) -> Void in
            fulfill("deferred")
        }
        
        var receivedValue: String! = nil

        waitForPromiseY = promise1.then(
            onFulfilled: { (value) in
                return Promise("")
            },
            onRejected: { (reason) in
                return deferred
            }
            ).thenWithContext(self, { (strongSelf, value) -> Void in
                receivedValue = value
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(receivedValue, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
        }
    }
    
    // 2.2.7.2 - If either onFulfilled or onRejected throws an exception e, promise2 must be rejected with e as the reason
    
    func testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> Void in
            fulfill(1)
        }
        
        var receivedReason: ErrorType! = nil
        
        waitForPromiseY = promise1.then(
            onFulfilled: { (value) -> String in
                throw TestError.ExpectedRejection
            },
            onRejected: { (reason) -> String in
                throw reason
            }
            ).handleWithContext(self, { (strongSelf, reason) in
                receivedReason = reason
                strongSelf.waitForPromiseY = nil
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(receivedReason as? TestError == TestError.ExpectedRejection, "If onFulfilled returns an error, promise2 must be rejected with the same reason")
        }
    }
    
    func testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> Void in
            reject(TestError.ExpectedRejection)
        }
        
        var receivedReason: ErrorType! = nil
        
        waitForPromiseY = promise1.then(
            onFulfilled: { (value) -> String in
                return "fulfilled"
            },
            onRejected: { (reason) -> String in
                 throw TestError.ExpectedRejection
            }
            ).handleWithContext(self, { (strongSelf, reason) in
                receivedReason = reason
                strongSelf.waitForPromiseY = nil
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(receivedReason as? TestError == TestError.ExpectedRejection, "If onRejected returns an error, promise2 must be rejected with the same reason")
        }
    }
    
    // 2.2.7.3 - If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1
    
    func testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue() {
        let expectation = self.expectationWithDescription("testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue")
        
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) in
            fulfill(1)
        }
        
        let promise2 = promise1.handle { (reason) -> Void in
        }
        
        var receivedValue = 2
        
        waitForPromiseA = promise2.thenWithContext(self) { (strongSelf, value) -> Void in
            receivedValue = value
            strongSelf.waitForPromiseY = nil
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertEqual(receivedValue, 1, "If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1")
        }
    }
    
    // 2.2.7.4 - If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1
    
    func testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason() {
        let expectation = self.expectationWithDescription("testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason")
        
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> Void in
            reject(TestError.ExpectedRejection)
        }
        
        let promise2 = promise1.then { value in
        }
        
        var receivedReason: ErrorType! = nil
        
        waitForPromiseA = promise2.handleWithContext(self) { (strongSelf, reason) in
            receivedReason = reason
            strongSelf.waitForPromiseA = nil
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(receivedReason as? TestError == TestError.ExpectedRejection, "If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1")
        }
    }
}
