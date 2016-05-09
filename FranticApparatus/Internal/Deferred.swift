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

final class Deferred<ValueType> {
    private let pendingOn: AnyObject?
    var onFulfilled: [(ValueType) -> Void]
    var onRejected: [(ErrorType) -> Void]
    
    convenience init() {
        self.init(pendingOn: nil, onFulfilled: [], onRejected: [])
    }
    
    convenience init<P>(pendingOn: Promise<P>) {
        self.init(pendingOn: pendingOn, onFulfilled: [], onRejected: [])
    }
    
    convenience init<P>(pendingOn: Promise<P>, onFulfilled: [(ValueType) -> Void], onRejected: [(ErrorType) -> Void]) {
        self.init(pendingOn: pendingOn, onFulfilled: onFulfilled, onRejected: onRejected)
    }
    
    private init(pendingOn: AnyObject?, onFulfilled: [(ValueType) -> Void], onRejected: [(ErrorType) -> Void]) {
        self.pendingOn = pendingOn
        self.onFulfilled = onFulfilled
        self.onRejected = onRejected
    }
}
