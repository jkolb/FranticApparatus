//
// FranticApparatusTests.swift
// FranticApparatusTests
//
// Copyright (c) 2014 Justin Kolb - http://franticapparatus.net
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

func dispatch_delay(when: Double, queue: dispatch_queue_t!, block: dispatch_block_t!) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(when * Double(NSEC_PER_SEC))), queue, block)
}

class FranticApparatusTests: XCTestCase {

    class ExpectedRejectionError : Error {
    }
    
    class UnexpectedRejectionError : Error {
    }
    
    // 2.1.1 - When pending, a promise:
    // 2.1.1.1 - may transition to either the fulfilled or rejected state
    
    func testNewlyCreatedPromiseIsPending() {
        let promise = Promise<Int>()
        var isPending = false
        
        switch promise.state {
        case .Pending:
            isPending = true
        default:
            isPending = false
        }
        
        XCTAssertTrue(isPending, "A newly created promise must be in the pending state")
    }
    
    func testWhenPendingIsFulfilledTransitionsToFulfilledState() {
        let promise = Promise<Int>()
        var isFulfilled = false
        
        promise.fulfill(1)
        
        let promiseA = promise.when { (value: Int) -> () in
            isFulfilled = true
        }
        
        XCTAssertTrue(isFulfilled, "When pending, a promise may transition to the fulfilled state")
    }
    
    func testWhenPendingIsRejectedTransitionsToRejectedState() {
        let promise = Promise<Int>()
        var isRejected = false
        
        promise.reject(ExpectedRejectionError())
        
        let promiseA = promise.catch { (reason: Error) -> () in
            isRejected = true
        }
        
        XCTAssertTrue(isRejected, "When pending, a promise may transition to the rejected state")
    }
    
    // 2.1.2 - When fulfilled, a promise:
    // 2.1.2.1 - must not transition to any other state
    
    func testFulfilledMustNotTranstionToAnyOtherState() {
        let promise = Promise<Int>()
        var isFulfilled = false
        
        promise.fulfill(1)
        
        let promiseA = promise.when { (value: Int) -> () in
            isFulfilled = true
        }

        promise.reject(ExpectedRejectionError())
        
        let promiseB = promise.catch { (reason: Error) -> () in
            isFulfilled = false
        }

        XCTAssertTrue(isFulfilled, "When fulfilled, a promise must not transition to any other state")
    }
    
    // 2.1.2.2 - must have a value, which must not change
    
    func testFulfilledMustHaveAValueWhichMustNotChange() {
        let promise = Promise<Int>()
        
        promise.fulfill(1)
        
        let promiseA = promise.when { (value: Int) -> () in
            XCTAssertEqual(value, 1, "When fulfilled, a promise must have a value, which must not change")
        }
        
        promise.fulfill(2)
        
        let promiseB = promise.when { (value: Int) -> () in
            XCTAssertEqual(value, 1, "When fulfilled, a promise must have a value, which must not change")
        }
    }
    
    // 2.1.3 - When rejected, a promise
    // 2.1.3.1 - must not transition to any other state
    
    func testRejectedMustNotTransitionToAnyOtherState() {
        let promise = Promise<Int>()
        var isRejected = false
        
        promise.reject(ExpectedRejectionError())
        
        let promiseA = promise.catch { (reason: Error) -> () in
            isRejected = true
        }
        
        promise.fulfill(1)
        
        let promiseB = promise.when { (value: Int) -> () in
            isRejected = false
        }
        
        XCTAssertTrue(isRejected, "When rejected, a promise must not transtion to any other state")
    }
    
    // 2.1.3.2 - must have a reason, which must not change
    
    func testRejectedMustHaveAReasonWhichMustNotChange() {
        let promise = Promise<Int>()
        
        promise.reject(ExpectedRejectionError())
        
        let promiseA = promise.catch { (reason: Error) -> () in
            XCTAssertTrue(reason is ExpectedRejectionError, "When rejected, a promise must have a reason, which must not change")
        }
        
        promise.reject(UnexpectedRejectionError())
        
        let promiseB = promise.catch { (reason: Error) -> () in
            XCTAssertTrue(reason is ExpectedRejectionError, "When rejected, a promise must have a reason, which must not change")
        }
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
        let promise1 = Promise<Int>()
        let promise2 = promise1.when({ (value: Int) -> () in
            XCTAssertEqual(value, 1, "If onFulfilled is a function it must be called after promise is fulfilled, with promise's value as its first argument")
            expectation.fulfill()
        })
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.2.3 - it must not be called more than once
    
    func testOnFulfilledMustNotBeCalledMoreThanOnce() {
        let expectation = self.expectationWithDescription("onFulfilled called")
        let promise1 = Promise<Int>()
        let promise2 = promise1.when({ (value: Int) -> () in
            XCTAssertEqual(promise1.onFulfilled.count, 0, "If onFulfilled is a function it must not be called more than once")
            expectation.fulfill()
        })
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }

    // 2.2.3 - If onRejected is a function
    
    // 2.2.3.1 - it must be called after promise is rejected, with promise's reason as its first argument
    
    // 2.2.3.3 - it must not be called more than once
    
    // 2.2.4 - onFulfilled or onRejected must not be called until the execution context stack contains only platform code.
    
    // 2.2.5 - onFulfilled and onRejected must be called as functions (i.e. with no this value).
    
    // 2.2.6 - then may be called multiple times on the same promise

    func testThenMayBeCalledMultipleTimesOnTheSamePromise() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int>()
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(1)
                callThenOnce.fulfill()
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            }
        )

        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(2)
                callThenTwice.fulfill()
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            }
        )
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(fulfilledToken.count, 2, "then may be called multiple times on the same promise")
        })
    }
    
    // 2.2.6.1 - if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then
    
    func testOnFulfilledCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var fulfilledToken = Array<Int>()
        
        let promise1 = Promise<Int>()
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(1)
                callThenOnce.fulfill()
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            }
        )
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                fulfilledToken.append(2)
                callThenTwice.fulfill()
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            }
        )
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: { (error: NSError!) -> Void in
            XCTAssertEqual(fulfilledToken[0], 1, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
            XCTAssertEqual(fulfilledToken[1], 2, "if/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then")
        })
    }
    
    // 2.2.6.2 - if/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then
    
    func testOnRejectedCallbacksMustExecuteInTheOrderOfTheirOriginatingCallsToThen() {
        var rejectedToken = Array<Int>()
        
        let promise1 = Promise<Int>()
        
        let callThenOnce = self.expectationWithDescription("Call then once")
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                rejectedToken.append(1)
                callThenOnce.fulfill()
                return .Failure(ExpectedRejectionError())
            }
        )
        
        let callThenTwice = self.expectationWithDescription("Call then twice")
        let promise3 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                rejectedToken.append(2)
                callThenTwice.fulfill()
                return .Failure(ExpectedRejectionError())
            }
        )
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.reject(ExpectedRejectionError())
        }
        
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
        let promise1 = Promise<Int>()
        let promise2: Any = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Success("")
            }, onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
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
        let promise1 = Promise<Int>()
        let deferred = Promise<String>()
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Deferred(deferred)
            },
            onRejected: { (reason: Error) -> Result<String> in
                return .Failure(reason)
            }
            ).when({ (value: String) -> () in
                XCTAssertEqual(value, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
                expectation.fulfill()
            })

        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            deferred.fulfill("deferred")
        }
        
        dispatch_delay(0.50, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    func testPromise1OnFulfilledReturnsAPendingDeferredPromise2WillFulfillWithValueOfDeferred() {
        let expectation = self.expectationWithDescription("")
        let promise1 = Promise<Int>()
        let deferred = Promise<String>()
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Deferred(deferred)
            },
            onRejected: { (reason: Error) -> Result<String> in
                return .Failure(reason)
            }
            ).when({ (value: String) -> () in
                XCTAssertEqual(value, "deferred", "If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).")
                expectation.fulfill()
            })
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        dispatch_delay(0.50, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            deferred.fulfill("deferred")
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.2 - If either onFulfilled or onRejected throws an exception e, promise2 must be rejected with e as the reason
    
    func testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnFulfilledReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        let promise1 = Promise<Int>()
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            },
            onRejected: { (reason: Error) -> Result<String> in
                return .Failure(reason)
            }
            ).catch({ (reason: Error) -> () in
                XCTAssertTrue(reason is ExpectedRejectionError, "If onFulfilled returns an error, promise2 must be rejected with the same reason")
                expectation.fulfill()
            })
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    func testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason() {
        let expectation = self.expectationWithDescription("testPromise1OnRejectedReturnsErrorPromise2MustBeRejectedWithSameErrorAsReason")
        let promise1 = Promise<Int>()
        let promise2 = promise1.then(
            onFulfilled: { (value: Int) -> Result<String> in
                return .Success("fulfilled")
            },
            onRejected: { (reason: Error) -> Result<String> in
                return .Failure(ExpectedRejectionError())
            }
            ).catch({ (reason: Error) -> () in
                XCTAssertTrue(reason is ExpectedRejectionError, "If onRejected returns an error, promise2 must be rejected with the same reason")
                expectation.fulfill()
            })
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.reject(UnexpectedRejectionError())
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.3 - If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1
    
    func testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue() {
        let expectation = self.expectationWithDescription("testFulfillingPromise1AndNotHandlingValueAndThenHandlingValueInPromise2ShouldBeSameValue")
        let promise1 = Promise<Int>()
        let promise2 = promise1.catch { (reason: Error) -> () in
        }
        let promise3 = promise2.when { (value: Int) -> () in
            XCTAssertEqual(value, 1, "If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1")
            expectation.fulfill()
        }
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.fulfill(1)
        }

        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
    
    // 2.2.7.4 - If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1
    
    func testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason() {
        let expectation = self.expectationWithDescription("testRejectingPromise1AndNotHandlingReasonAndThenHandlingReasonInPromise2ShouldBeSameReason")
        let promise1 = Promise<Int>()
        let promise2 = promise1.when { (value: Int) -> () in
        }
        let promise3 = promise2.catch { (reason: Error) -> () in
            XCTAssertTrue(reason is ExpectedRejectionError, "If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1")
            expectation.fulfill()
        }
        
        dispatch_delay(0.25, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            promise1.reject(ExpectedRejectionError())
        }
        
        self.waitForExpectationsWithTimeout(1.0) { (error: NSError!) -> () in
        }
    }
}
