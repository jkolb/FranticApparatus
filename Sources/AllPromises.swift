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

public func all<Value, Promises : Collection>(_ promises: Promises) -> Promise<[Value]> where Promises.Iterator.Element == Promise<Value> {
    return Promise<[Value]>(pending: promises) { (fulfill, reject) in
        let all = AllPromises<Int, Value>(
            count: numericCast(promises.count),
            fulfill: { (values) in
                let sortedValues = values.sorted(by: { $0.key < $1.key }).map({ $0.value })
                
                fulfill(sortedValues)
            },
            reject: reject
        )
        
        for (index, promise) in promises.enumerated() {
            promise.onResolve(
                fulfill: { (value) in
                    all.fulfill(value: value, for: index)
                },
                reject: { (reason) in
                    all.reject(reason: reason, for: index)
                }
            )
        }
    }
}

public func all<Key : Hashable, Value>(_ promises: [Key:Promise<Value>]) -> Promise<[Key:Value]> {
    return Promise<[Key:Value]>(pending: promises) { (fulfill, reject) in
        let all = AllPromises<Key, Value>(
            count: numericCast(promises.count),
            fulfill: fulfill,
            reject: reject
        )
        
        for (key, promise) in promises {
            promise.onResolve(
                fulfill: { (value) in
                    all.fulfill(value: value, for: key)
                },
                reject: { (reason) in
                    all.reject(reason: reason, for: key)
                }
            )
        }
    }
}

fileprivate final class AllPromises<Key : Hashable, Value> {
    fileprivate let lock: Lock
    fileprivate let count: Int
    fileprivate var values: [Key:Value]
    fileprivate var reasons: [Key:Error]
    fileprivate let fulfill: ([Key:Value]) -> Void
    fileprivate let reject: (Error) -> Void
    
    fileprivate init(count: Int, fulfill: @escaping ([Key:Value]) -> Void, reject: @escaping (Error) -> Void) {
        self.lock = Lock()
        self.count = count
        self.values = [Key:Value]()
        self.reasons = [Key:Error]()
        self.fulfill = fulfill
        self.reject = reject
    }
    
    fileprivate func fulfill(value: Value, for key: Key) {
        lock.lock()
        values[key] = value
        
        if values.count == count {
            fulfill(values)
        }
        
        lock.unlock()
    }
    
    fileprivate func reject(reason: Error, for key: Key) {
        lock.lock()
        reasons[key] = reason
        
        if reasons.count == 1 {
            reject(reason)
        }

        lock.unlock()
    }
}
