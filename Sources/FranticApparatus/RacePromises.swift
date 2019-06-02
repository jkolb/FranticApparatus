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

public struct ErrorArray : Error, CustomStringConvertible {
    public let errors: [Error]
    
    public init(errors: [Error]) {
        self.errors = errors
    }
    
    public var description: String {
        return self.errors.description
    }
}

public func race<Value, Promises : Collection>(_ promises: Promises) -> Promise<Value> where Promises.Iterator.Element == Promise<Value> {
    return Promise<Value> { (fulfill, reject) in
        let race = RacePromises<Value>(count: numericCast(promises.count), fulfill: fulfill, reject: { (reasons) in
                reject(ErrorArray(errors: reasons))
        })
        
        for promise in promises {
            promise.addCallback(context: ThreadContext.defaultContext, whenFulfilled: { (value) in
                race.fulfill(value: value)
            }, whenRejected: { (reason) in
                race.reject(reason: reason)
            })
        }
    }
}

private final class RacePromises<Value> {
    private let lock: Lock
    private let count: Int
    private let fulfill: (Value) -> Void
    private let reject: ([Error]) -> Void
    private var values: [Value]
    private var reasons: [Error]
    
    fileprivate init(count: Int, fulfill: @escaping (Value) -> Void, reject: @escaping ([Error]) -> Void) {
        self.lock = Lock()
        self.count = count
        self.fulfill = fulfill
        self.reject = reject
        self.values = [Value]()
        self.reasons = [Error]()
        
        values.reserveCapacity(count)
        reasons.reserveCapacity(count)
    }
    
    fileprivate func fulfill(value: Value) {
        lock.lock()
        values.append(value)
        
        if values.count == 1 {
            fulfill(value)
        }
        
        lock.unlock()
    }
    
    fileprivate func reject(reason: Error) {
        lock.lock()
        reasons.append(reason)
        
        if reasons.count == count {
            reject(reasons)
        }
        
        lock.unlock()
    }
}
