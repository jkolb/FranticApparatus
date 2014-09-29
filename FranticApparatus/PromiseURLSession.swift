//
// PromiseURLSession.swift
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

public class PromiseURLSession : NSObject, NSURLSessionDataDelegate, Synchronizable {
    struct PromisedData {
        weak var promise: Promise<(response: NSURLResponse, data: NSData)>?
        var data: NSMutableData
    }
    
    public let synchronizationQueue = GCDQueue.serial("net.franticapparatus.PromiseSession")
    let session: NSURLSession!
    var taskPromisedData = Dictionary<NSURLSessionTask, PromisedData>(minimumCapacity: 8)
    
    public init(configuration: NSURLSessionConfiguration) {
        super.init()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue())
    }

    func complete(task: NSURLSessionTask, error: NSError?) {
        synchronizeRead(self) { (promiseSession) in
            if let promisedData = promiseSession.taskPromisedData[task] {
                if error == nil {
                    promisedData.promise?.fulfill((response: task.response!, data: promisedData.data.copy() as NSData))
                } else {
                    promisedData.promise?.reject(Error())
                }
            }
            
            synchronizeWrite(promiseSession) { (promiseSession) in
                promiseSession.taskPromisedData[task] = nil
            }
        }
    }
    
    func accumulate(task: NSURLSessionTask, data: NSData) {
        synchronizeRead(self) { (promiseSession) in
            if let promisedData = promiseSession.taskPromisedData[task] {
                data.enumerateByteRangesUsingBlock { (bytes, range, stop) -> () in
                    promisedData.data.appendBytes(bytes, length: range.length)
                }
            }
        }
    }
    
    public func promise(request: NSURLRequest) -> Promise<(response: NSURLResponse, data: NSData)> {
        let promise = Promise<(response: NSURLResponse, data: NSData)>()
        let threadSafeRequest = request.copy() as NSURLRequest
        
        synchronizeWrite(self) { [weak promise] (promiseSession) in
            if let strongPromise = promise {
                let dataTask = promiseSession.session.dataTaskWithRequest(threadSafeRequest)
                let promisedData = PromisedData(promise: strongPromise, data: NSMutableData(capacity: 4096))
                promiseSession.taskPromisedData[dataTask] = promisedData
                dataTask.resume()
            }
        }
        
        return promise
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        accumulate(dataTask, data: data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        complete(task, error: error)
    }
}