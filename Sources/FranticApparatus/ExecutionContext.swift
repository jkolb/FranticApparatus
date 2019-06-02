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

import Dispatch
import Foundation

public protocol ExecutionContext : class {
    func execute(_ block: @escaping () -> Void)
}

extension DispatchQueue : ExecutionContext {
    public func execute(_ block: @escaping () -> Void) {
        async(execute: DispatchWorkItem(block: block))
    }
}

extension OperationQueue : ExecutionContext {
    public func execute(_ block: @escaping () -> Void) {
        addOperation(block)
    }
}

public final class ThreadContext : Thread, ExecutionContext {
    private let condition: NSCondition
    private var queue: [() -> Void]
    
    public init(name: String? = nil, autostart: Bool = true) {
        self.condition = NSCondition()
        self.queue = []
        super.init()
        self.name = name
        if autostart {
            start()
        }
    }
    
    public override func main() {
        while true {
            condition.lock()
            while queue.isEmpty {
                condition.wait()
            }
            let block = queue.popLast()
            condition.unlock()
            block?()
        }
    }
    
    public func execute(_ block: @escaping () -> Void) {
        condition.lock()
        queue.insert(block, at: 0)
        condition.signal()
        condition.unlock()
    }
}
