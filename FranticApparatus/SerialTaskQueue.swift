//
// SerialTaskQueue.swift
// FranticApparatus
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

import Foundation

protocol SerialTaskQueue {
    func dispatch(task: () -> ())
}

final class GCDSerialTaskQueue : SerialTaskQueue {
    let queue: dispatch_queue_t
    
    required init(main: Bool = false) {
        if main {
            queue = dispatch_get_main_queue()
        } else {
            queue = dispatch_queue_create("net.franticapparatus.GCDSerialTaskQueue", DISPATCH_QUEUE_SERIAL)
        }
    }
    
    class func main() -> SerialTaskQueue {
        return self(main: true)
    }
    
    func dispatch(task: () -> ()) {
        dispatch_async(queue, task)
    }
}

final class NSOperationSerialTaskQueue : SerialTaskQueue {
    let queue: NSOperationQueue
    
    required init(main: Bool = false) {
        if main {
            queue = NSOperationQueue.mainQueue()
        } else {
            queue = NSOperationQueue()
            queue.maxConcurrentOperationCount = 1
            queue.name = "net.franticapparatus.NSOperationSerialTaskQueue"
        }
    }
    
    class func main() -> SerialTaskQueue {
        return self(main: true)
    }
    
    func dispatch(task: () -> ()) {
        queue.addOperationWithBlock(task)
    }
}

final class ImmediateSerialTaskQueue : SerialTaskQueue {
    func dispatch(task: () -> ()) {
        task()
    }
}
