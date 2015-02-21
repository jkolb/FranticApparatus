//
// FranticApparatusTests.swift
// FranticApparatusTests
//
// Copyright (c) 2014-2015 Justin Kolb - http://franticapparatus.net
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
//

import XCTest
import FranticApparatus

class FranticApparatusTests: XCTestCase {

    class ExpectedRejectionError : Error {
    }
    
    class UnexpectedRejectionError : Error {
    }
    
    // 2.1.1 - When pending, a promise:
    // 2.1.1.1 - may transition to either the fulfilled or rejected state
    
//    func testNewlyCreatedPromiseIsPending() {
//        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
//        }
//        var isPending = false
//        
//        switch promise.state {
//        case .Pending:
//            isPending = true
//        default:
//            isPending = false
//        }
//        
//        XCTAssertTrue(isPending, "A newly created promise must be in the pending state")
//    }
    
    func testWhenPendingIsFulfilledTransitionsToFulfilledState() {
        let expectation = self.expectationWithDescription("onFulfilled called")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        var isFulfilled = false
        
        let promiseA = promise.then { (value: Int) -> () in
            isFulfilled = true
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertTrue(isFulfilled, "When pending, a promise may transition to the fulfilled state")
        })
    }
    
    func testWhenPendingIsRejectedTransitionsToRejectedState() {
        let expectation = self.expectationWithDescription("onRejected called")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            reject(ExpectedRejectionError())
        }
        var isRejected = false

        let promiseA = promise.catch { (reason: Error) -> () in
            isRejected = true
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertTrue(isRejected, "When pending, a promise may transition to the rejected state")
        })
    }
    
    // 2.1.2 - When fulfilled, a promise:
    // 2.1.2.1 - must not transition to any other state
    
    func testFulfilledMustNotTranstionToAnyOtherState() {
        let promiseFulfilled1 = self.expectationWithDescription("onFulfilled called once")
        let promiseFulfilled2 = self.expectationWithDescription("onFulfilled called twice")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
            reject(ExpectedRejectionError())
        }
        var isFulfilled = false
        
        let promiseA = promise.then { (value: Int) -> () in
            isFulfilled = true
            promiseFulfilled1.fulfill()
        }
        
        let promiseB = promise.then(
            onFulfilled: { (value: Int) -> Result<Int> in
                isFulfilled = true
                promiseFulfilled2.fulfill()
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<Int> in
                isFulfilled = false
                promiseFulfilled2.fulfill()
                return Result(reason)
            }
        )

        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertTrue(isFulfilled, "When fulfilled, a promise must not transition to any other state")
        })

    }
    
    // 2.1.2.2 - must have a value, which must not change
    
    func testFulfilledMustHaveAValueWhichMustNotChange() {
        let promiseFulfilled1 = self.expectationWithDescription("onFulfilled called once")
        let promiseFulfilled2 = self.expectationWithDescription("onFulfilled called twice")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
            fulfill(2)
        }
        var fulfilledValue = 0
        
        let promiseA = promise.then { (value: Int) -> () in
            fulfilledValue = value
            promiseFulfilled1.fulfill()
        }

        let promiseB = promise.then { (value: Int) -> () in
            fulfilledValue = value
            promiseFulfilled2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(fulfilledValue, 1, "When fulfilled, a promise must have a value, which must not change")
        })
    }
    
    // 2.1.3 - When rejected, a promise
    // 2.1.3.1 - must not transition to any other state
    
    func testRejectedMustNotTransitionToAnyOtherState() {
        let promiseRejected1 = self.expectationWithDescription("onRejected called once")
        let promiseRejected2 = self.expectationWithDescription("onRejected called twice")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            reject(ExpectedRejectionError())
            fulfill(1)
        }
        var isRejected = false
        
        let promiseA = promise.catch { (reason: Error) -> () in
            isRejected = true
            promiseRejected1.fulfill()
        }
        
        let promiseB = promise.then(
            onFulfilled: { (value: Int) -> Result<Int> in
                isRejected = false
                promiseRejected2.fulfill()
                return Result(value)
            },
            onRejected: { (reason: Error) -> Result<Int> in
                isRejected = true
                promiseRejected2.fulfill()
                return Result(reason)
            }
        )
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertTrue(isRejected, "When rejected, a promise must not transtion to any other state")
        })
    }
    
    // 2.1.3.2 - must have a reason, which must not change
    
    func testRejectedMustHaveAReasonWhichMustNotChange() {
        let promiseRejected1 = self.expectationWithDescription("onRejected called once")
        let promiseRejected2 = self.expectationWithDescription("onRejected called twice")
        let promise = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            reject(ExpectedRejectionError())
            reject(UnexpectedRejectionError())
        }
        var rejectedReason: Error = Error()
        
        let promiseA = promise.catch { (reason: Error) -> () in
            rejectedReason = reason
            promiseRejected1.fulfill()
        }
        
        let promiseB = promise.catch { (reason: Error) -> () in
            rejectedReason = reason
            promiseRejected2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertTrue(rejectedReason is ExpectedRejectionError, "When rejected, a promise must have a reason, which must not change")
        })
    }
    
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
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        let promise2 = promise1.then({ (value: Int) -> () in
            XCTAssertEqual(value, 1, "If onFulfilled is a function it must be called after promise is fulfilled, with promise's value as its first argument")
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.2.3 - it must not be called more than once
    
//    func testOnFulfilledMustNotBeCalledMoreThanOnce() {
//        let expectation = self.expectationWithDescription("onFulfilled called")
//        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> () in
//            fulfill(1)
//        }
//        let promise2 = promise1.when({ (value: Int) -> () in
//            XCTAssertEqual(promise1.onFulfilled.count, 0, "If onFulfilled is a function it must not be called more than once")
//            expectation.fulfill()
//        })
//        
//        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
//        }
//    }

    // 2.2.3 - If onRejected is a function
    
    // 2.2.3.1 - it must be called after promise is rejected, with promise's reason as its first argument
    
    // 2.2.3.3 - it must not be called more than once
    
    // 2.2.4 - onFulfilled or onRejected must not be called until the execution context stack contains only platform code.
    
    // 2.2.5 - onFulfilled and onRejected must be called as functions (i.e. with no this value).
    
    // 2.2.6 - then may be called multiple times on the same promise

    func testThenMayBeCalledMultipleTimesOnTheSamePromise() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(1)
                callThenOnce.fulfill()
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
        )

        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(2)
                callThenTwice.fulfill()
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
        )
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(fulfilledToken.count, 2, "then may be called multiple times on the same promise")
        })
    }
    
    // 2.2.6.1 - if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then
    
    func testOnFulfilledCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(1)
                callThenOnce.fulfill()
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
        )
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(2)
                callThenTwice.fulfill()
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
        )
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(fulfilledToken[0], 1, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
            XCTAssertEqual(fulfilledToken[1], 2, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
        })
    }
    
    // 2.2.6.2 - if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then
    
    func testOnRejectedCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var rejectedToken = Array<Int>()
        
        let promise1 = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            reject(ExpectedRejectionError())
        }
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                rejectedToken.append(1)
                callThenOnce.fulfill()
                return Result(ExpectedRejectionError())
            }
        )
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                rejectedToken.append(2)
                callThenTwice.fulfill()
                return Result(ExpectedRejectionError())
            }
        )
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(rejectedToken[0], 1, "if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then")
            XCTAssertEqual(rejectedToken[1], 2, "if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then")
        })
    }
    
    // 2.2.7 - then must return a promise. promise2 = promise1.then(onFulfilled, onRejected)
    //    **** The static type system limits the types that can be returned by the next promise to
    //    **** just 1 type. This seems like a reasonable limitation as it seems like each callback
    //    **** should do "one thing" well. If multiple types are really needed a tuple or enum can
    //    **** be used as the one type instead.
    func testThenMustReturnAPromise() {
        let promise1  = Promise<Int> { (fulfill, reject, isCancelled) -> () in
        }
        let promise2: Any = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
        )
        
        var thenReturnedPromise = false
        
        if promise2 is Promise<String> {
            thenReturnedPromise = true
        }

        XCTAssertTrue(thenReturnedPromise, "then must return a promise")
    }
    
    // 2.2.7.1 - If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).
    
    func testPromise1OnFulfilledReturnsAFulfilledDeferredPromise2WillFulfillWithValueOfDeferred() {
        let expectation = self.expectationWithDescription("")
        let promise1  = Promise<Int> { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        let deferred = Promise<String>() { (fulfill, reject, isCancelled) -> () in
            fulfill("deferred")
        }
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result(deferred)
            },
            onRejected: { (reason: Error) -> Result<String> in
                return Result(reason)
            }
            ).then({ (value: String) -> () in
                XCTAssertEqual(value, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    func testPromise1OnFulfilledReturnsAPendingDeferredPromise2WillFulfillWithValueOfDeferred() {
        let expectation = self.expectationWithDescription("")
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        let deferred = Promise<String>() { (fulfill, reject, isCancelled) -> () in
            fulfill("deferred")
        }
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result(deferred)
            },
            onRejected: { (reason: Error) -> Result<String> in
                return Result(reason)
            }
            ).then({ (value: String) -> () in
                XCTAssertEqual(value, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.2 - If either onFulfilled or onRejected throws an exception e, promise2 must be rejected with e as the reason
    
    func testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result(ExpectedRejectionError())
            },
            onRejected: { (reason: Error) -> Result<String> in
                return Result(reason)
            }
            ).catch({ (reason: Error) -> () in
                XCTAssertTrue(reason is ExpectedRejectionError, "If onFulfilled returns an error, promise2 must be rejected with the same reason")
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    func testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> () in
            reject(UnexpectedRejectionError())
        }
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return Result("fulfilled")
            },
            onRejected: { (reason: Error) -> Result<String> in
                return Result(ExpectedRejectionError())
            }
            ).catch({ (reason: Error) -> () in
                XCTAssertTrue(reason is ExpectedRejectionError, "If onRejected returns an error, promise2 must be rejected with the same reason")
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.3 - If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1
    
    func testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue() {
        let expectation = self.expectationWithDescription("testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue")
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> () in
            fulfill(1)
        }
        let promise2 = promise1.catch { (reason: Error) -> () in
        }
        let promise3 = promise2.then { (value: Int) -> () in
            XCTAssertEqual(value, 1, "If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.4 - If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1
    
    func testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason() {
        let expectation = self.expectationWithDescription("testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason")
        let promise1 = Promise<Int>() { (fulfill, reject, isCancelled) -> () in
            reject(ExpectedRejectionError())
        }
        let promise2 = promise1.then { (value: Int) -> () in
        }
        let promise3 = promise2.catch { (reason: Error) -> () in
            XCTAssertTrue(reason is ExpectedRejectionError, "If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
}
