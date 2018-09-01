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

final class Deferred<Value> {
    private let pending: Any?
    var onFulfilled: [(Value) -> Void]
    var onRejected: [(Error) -> Void]
    
    convenience init() {
        self.init(pending: nil, onFulfilled: [], onRejected: [])
    }
    
    convenience init(pending: Any) {
        self.init(pending: pending, onFulfilled: [], onRejected: [])
    }
    
    convenience init<P>(pendingPromise: Promise<P>?) {
        self.init(pending: pendingPromise, onFulfilled: [], onRejected: [])
    }
    
    convenience init<P>(pendingPromise: Promise<P>, onFulfilled: [(Value) -> Void], onRejected: [(Error) -> Void]) {
        self.init(pending: pendingPromise, onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    private init(pending: Any?, onFulfilled: [(Value) -> Void], onRejected: [(Error) -> Void]) {
        self.pending = pending
        self.onFulfilled = onFulfilled
        self.onRejected = onRejected
    }
}
