//
//  SerialTaskQueue.swift
//  FranticApparatus
//
//  Created by Justin Kolb on 9/22/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
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
            queue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL)
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
