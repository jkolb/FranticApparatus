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

public final class Promise<ValueType> : Thenable {
    private let lock: Lock
    private var state: State<ValueType>
    
    public init(@noescape _ promise: (fulfill: (ValueType) -> Void, reject: (ErrorType) -> Void, isCancelled: () -> Bool) -> Void) {
        self.lock = Lock()
        self.state = .Pending(Deferred())

        let isCancelled: () -> Bool = { [weak self] in
            return self == nil
        }
        
        promise(fulfill: weakifyFulfill(), reject: weakifyReject(), isCancelled: isCancelled)
    }
    
    public func thenOn<ResultType>(dispatcher: Dispatcher, onFulfilled: (ValueType) throws -> Result<ResultType>, onRejected: (ErrorType) throws -> Result<ResultType>) -> Promise<ResultType> {
        return Promise<ResultType>(pendingOn: self) { (resolve, reject) in
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

    private init<R>(pendingOn: Promise<R>, @noescape _ resolver: (resolve: (Result<ValueType>) -> Void, reject: (ErrorType) -> Void) -> Void) {
        self.lock = Lock()
        self.state = .Pending(Deferred(pendingOn: pendingOn))
        
        resolver(resolve: weakifyResolve(), reject: weakifyReject())
    }
    
    private func weakifyFulfill() -> (ValueType) -> Void {
        return { [weak self] (value) in
            guard let strongSelf = self else { return }
            
            strongSelf.fulfill(value)
        }
    }
    
    private func fulfill(value: ValueType) {
        lock.lock()
        switch state {
        case .Pending(let deferred):
            state = .Fulfilled(value)
            let deferredOnFulfilled = deferred.onFulfilled
            lock.unlock()
            
            for onFulfilled in deferredOnFulfilled {
                onFulfilled(value)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func weakifyReject() -> (ErrorType) -> Void {
        return { [weak self] (reason) in
            guard let strongSelf = self else { return }
            
            strongSelf.reject(reason)
        }
    }
    
    private func reject(reason: ErrorType) {
        lock.lock()
        switch state {
        case .Pending(let deferred):
            state = .Rejected(reason)
            let deferredOnRejected = deferred.onRejected
            lock.unlock()
            
            for onRejected in deferredOnRejected {
                onRejected(reason)
            }
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func pendOn(promise: Promise<ValueType>) {
        precondition(promise !== self)

        lock.lock()
        switch state {
        case .Pending(let deferred):
            state = .Pending(Deferred(pendingOn: promise, onFulfilled: deferred.onFulfilled, onRejected: deferred.onRejected))
            lock.unlock()
            promise.onResolve(fulfill: weakifyFulfill(), reject: weakifyReject())
            
        default:
            fatalError("Duplicate attempt to resolve promise")
        }
    }
    
    private func weakifyResolve() -> (Result<ValueType>) -> Void {
        return { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            strongSelf.resolve(result)
        }
    }

    private func resolve(result: Result<ValueType>) {
        switch result {
        case .Value(let value):
            fulfill(value)
            
        case .Defer(let promise):
            pendOn(promise)
        }
    }
    
    private func onResolve(fulfill fulfill: (ValueType) -> Void, reject: (ErrorType) -> Void) {
        lock.lock()
        switch state {
        case .Fulfilled(let value):
            lock.unlock()
            fulfill(value)
            
        case .Rejected(let reason):
            lock.unlock()
            reject(reason)
            
        case .Pending(let deferred):
            deferred.onFulfilled.append(fulfill)
            deferred.onRejected.append(reject)
            lock.unlock()
        }
    }
}
