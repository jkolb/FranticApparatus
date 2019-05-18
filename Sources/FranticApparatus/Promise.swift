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

public final class Promise<Value> : Thenable {
    private let lock: Lock
    private var state: State<Value>
    
    public init(_ promise: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void, _ isCancelled: @escaping () -> Bool) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred())

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        promise(weakify(Promise.fulfill), weakify(Promise.reject), isCancelled)
    }

    private func weakify<V>(_ method: @escaping (Promise<Value>) -> (V) -> Void) -> (V) -> Void {
        return { [weak self] (value: V) in
            guard let self = self else { return }
            
            method(self)(value)
        }
    }

    public func then<ResultingValue>(on dispatcher: Dispatcher, onFulfilled: @escaping (Value) throws -> Fulfilled<ResultingValue>, onRejected: @escaping (Error) throws -> Fulfilled<ResultingValue>) -> Promise<ResultingValue> {
        return Promise<ResultingValue>(pendingPromise: self) { (resolve, reject) in
            self.onResolve(
                fulfill: { (value) in
                    dispatcher.dispatch {
                        do {
                            let result = try onFulfilled(value)
                            resolve(result)
                        }
                        catch {
                            reject(error)
                        }
                    }
                },
                reject: { (reason) in
                    dispatcher.dispatch {
                        do {
                            let result = try onRejected(reason)
                            resolve(result)
                        }
                        catch {
                            reject(error)
                        }
                    }
                }
            )
        }
    }
    
    init(pending: Any, _ resolver: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred(pending: pending))
        
        resolver(weakify(Promise.fulfill), weakify(Promise.reject))
    }

    private init<PendingValue>(pendingPromise: Promise<PendingValue>, _ resolver: (_ resolve: @escaping (Fulfilled<Value>) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.lock = Lock()
        self.state = .pending(Deferred(pendingPromise: pendingPromise))
        
        resolver(weakify(Promise.resolve), weakify(Promise.reject))
    }
    
    private func fulfill(_ value: Value) {
        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .fulfilled(value)
            lock.unlock()
            
            for onFulfilled in deferred.onFulfilled {
                onFulfilled(value)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func reject(_ reason: Error) {
        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .rejected(reason)
            lock.unlock()
            
            for onRejected in deferred.onRejected {
                onRejected(reason)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func pendOn(_ promise: Promise<Value>) {
        precondition(promise !== self)

        lock.lock()
        
        switch state {
        case .pending(let deferred):
            state = .pending(Deferred(pendingPromise: promise, onFulfilled: deferred.onFulfilled, onRejected: deferred.onRejected))
            lock.unlock()
            promise.onResolve(fulfill: weakify(Promise.fulfill), reject: weakify(Promise.reject))
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }

    private func resolve(_ result: Fulfilled<Value>) {
        switch result {
        case .value(let value):
            fulfill(value)
            
        case .promise(let promise):
            pendOn(promise)
        }
    }
    
    func onResolve(fulfill: @escaping (Value) -> Void, reject: @escaping (Error) -> Void) {
        lock.lock()
        
        switch state {
        case .fulfilled(let value):
            lock.unlock()
            fulfill(value)
            
        case .rejected(let reason):
            lock.unlock()
            reject(reason)
            
        case .pending(let deferred):
            deferred.onFulfilled.append(fulfill)
            deferred.onRejected.append(reject)
            lock.unlock()
        }
    }
}
