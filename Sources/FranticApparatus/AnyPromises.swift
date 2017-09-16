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

public struct AnyResult<Key : Hashable, Value> {
    public let values: [Key:Value]
    public let reasons: [Key:Error]
    
    public init(values: [Key:Value], reasons: [Key:Error]) {
        precondition(values.count > 0)
        precondition(reasons.count >= 0)
        precondition(Set<Key>(values.keys).intersection(Set<Key>(reasons.keys)).count == 0)
        self.values = values
        self.reasons = reasons
    }
    
    public func requiredValue(for key: Key) throws -> Value {
        if let value = values[key] {
            return value
        }
        else {
            throw reasons[key] ?? PromiseError.unknownReason
        }
    }
}

public func any<Key, Value>(_ promises: [Key:Promise<Value>]) -> Promise<AnyResult<Key, Value>> {
    return Promise<AnyResult<Key, Value>>(pending: promises) { (fulfill, reject) in
        let any = AnyPromises<Key, Value>(
            count: promises.count,
            fulfill: fulfill,
            reject: { (reasons) in
                reject(ErrorDictionary<Key>(errors: reasons))
        }
        )
        
        for (key, promise) in promises {
            promise.onResolve(
                fulfill: { (value) in
                    any.fulfill(value: value, for: key)
            },
                reject: { (reason) in
                    any.reject(reason: reason, for: key)
            }
            )
        }
    }
}

fileprivate final class AnyPromises<Key : Hashable, Value> {
    fileprivate let lock: Lock
    fileprivate let count: Int
    fileprivate let fulfill: (AnyResult<Key, Value>) -> Void
    fileprivate let reject: ([Key:Error]) -> Void
    fileprivate var values: [Key:Value]
    fileprivate var reasons: [Key:Error]
    
    fileprivate init(count: Int, fulfill: @escaping (AnyResult<Key, Value>) -> Void, reject: @escaping ([Key:Error]) -> Void) {
        self.lock = Lock()
        self.count = count
        self.fulfill = fulfill
        self.reject = reject
        self.values = [Key:Value](minimumCapacity: count)
        self.reasons = [Key:Error](minimumCapacity: count)
    }
    
    fileprivate func fulfill(value: Value, for key: Key) {
        lock.lock()
        values[key] = value
        
        if values.count + reasons.count == count {
            fulfill(AnyResult<Key, Value>(values: values, reasons: reasons))
        }
        
        lock.unlock()
    }
    
    fileprivate func reject(reason: Error, for key: Key) {
        lock.lock()
        reasons[key] = reason
        
        if reasons.count == count {
            reject(reasons)
        }
        else if values.count + reasons.count == count {
            fulfill(AnyResult<Key, Value>(values: values, reasons: reasons))
        }
        
        lock.unlock()
    }
}
