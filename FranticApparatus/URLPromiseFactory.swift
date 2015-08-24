//
// URLPromiseFactory.swift
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

import Foundation

public enum URLPromiseFactoryError : ErrorType {
    case OutOfMemory
}

public struct URLResponse {
    public let metadata: NSURLResponse // NSURLResponse encapsulates the metadata associated with a URL load.
    public let data: NSData
    
    public init(metadata: NSURLResponse, data: NSData) {
        self.metadata = metadata
        self.data = data
    }
}

public protocol URLPromiseFactory {
    func promise(request: NSURLRequest) -> Promise<URLResponse>
}

extension NSURLSession : URLPromiseFactory {
    public func promise(request: NSURLRequest) -> Promise<URLResponse> {
        let promiseDelegate = delegate as! SimpleURLSessionDataDelegate
        return promiseDelegate.URLSession(self, promiseForRequest: request)
    }
}

public class SimpleURLSessionDataDelegate : NSObject, NSURLSessionDataDelegate, Synchronizable {
    struct CallbacksAndData {
        let fulfill: (URLResponse) -> ()
        let reject: (ErrorType) -> ()
        let isCancelled: () -> Bool
        let data: NSMutableData
        
        var responseData: NSData {
            return data.copy() as! NSData
        }
    }
    
    var callbacksAndData = Dictionary<NSURLSessionTask, CallbacksAndData>(minimumCapacity: 8)
    public let synchronizationQueue: DispatchQueue = GCDQueue.concurrent("net.franticapparatus.PromiseSession")
    
    func complete(task: NSURLSessionTask, error: NSError?) {
        synchronizeRead { delegate in
            if let callbacksAndData = delegate.callbacksAndData[task] {
                if error == nil {
                    let value = URLResponse(metadata: task.response!, data: callbacksAndData.responseData)
                    callbacksAndData.fulfill(value)
                } else {
                    callbacksAndData.reject(error!)
                }
            }
            
            delegate.synchronizeWrite { delegate in
                delegate.callbacksAndData[task] = nil
            }
        }
    }
    
    func accumulate(task: NSURLSessionTask, data: NSData) {
        synchronizeWrite { delegate in
            if let callbacksAndData = delegate.callbacksAndData[task] {
                if callbacksAndData.isCancelled() {
                    task.cancel()
                    delegate.callbacksAndData[task] = nil
                } else {
                    data.enumerateByteRangesUsingBlock { (bytes, range, stop) -> () in
                        callbacksAndData.data.appendBytes(bytes, length: range.length)
                    }
                }
            }
        }
    }
    
    func promise(session: NSURLSession, request: NSURLRequest) -> Promise<URLResponse> {
        return Promise<URLResponse> { (fulfill, reject, isCancelled) -> () in
            let threadSafeRequest = request.copy() as! NSURLRequest
            
            self.synchronizeWrite { delegate in
                if isCancelled() {
                    return;
                }
                
                if let data = NSMutableData(capacity: 4096) {
                    let dataTask = session.dataTaskWithRequest(threadSafeRequest)
                    let callbacksAndData = CallbacksAndData(fulfill: fulfill, reject: reject, isCancelled: isCancelled, data: data)
                    delegate.callbacksAndData[dataTask] = callbacksAndData
                    dataTask.resume()
                } else {
                    reject(URLPromiseFactoryError.OutOfMemory)
                }
            }
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        accumulate(dataTask, data: data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        complete(task, error: error)
    }
    
    public func URLSession(session: NSURLSession, promiseForRequest request: NSURLRequest) -> Promise<URLResponse> {
        return promise(session, request: request)
    }
}
