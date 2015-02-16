//
// DispatchQueue.swift
// FranticApparatus
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

import Dispatch

public protocol DispatchQueue : class, Printable {
    func dispatch(block: () -> ())
    func dispatchAndWait(block: () -> ())
    func dispatchSerialized(block: () -> ())
}

public final class GCDQueue : DispatchQueue {
    let queue: dispatch_queue_t
    
    public init(queue: dispatch_queue_t) {
        self.queue = queue
    }
    
    public class func main() -> GCDQueue {
        return GCDQueue(queue: dispatch_get_main_queue())
    }
    
    public class func serial(name: String) -> GCDQueue {
        return GCDQueue(queue: dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL))
    }
    
    public class func concurrent(name: String) -> GCDQueue {
        return GCDQueue(queue: dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT))
    }
    
    public class func globalPriorityDefault() -> GCDQueue {
        return GCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    }
    
    public class func globalPriorityBackground() -> GCDQueue {
        return GCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    }
    
    public class func globalPriorityHigh() -> GCDQueue {
        return GCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
    }
    
    public class func globalPriorityLow() -> GCDQueue {
        return GCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))
    }
    
    public func dispatch(block: () -> ()) {
        dispatch_async(queue, block)
    }
    
    public func dispatchAndWait(block: () -> ()) {
        dispatch_sync(queue, block)
    }
    
    public func dispatchSerialized(block: () -> ()) {
        dispatch_barrier_async(queue, block)
    }

    public var description: String {
        let labelBytes = UnsafePointer<CChar>(dispatch_queue_get_label(queue))
        let (string, _) = String.fromCStringRepairingIllFormedUTF8(labelBytes)
        return string ?? "nil"
    }
}
