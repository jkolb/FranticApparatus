//
// ViewController.swift
// FranticApparatusExample_iOS
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

import UIKit
import FranticApparatus

class UnexpectedResponseError : Error {}
class UnexpectedHTTPStatusCodeError : Error {}
class MissingContentTypeError : Error {}
class UnexpectedContentTypeError : Error {}
class LinkListingParseError : Error {}

class ViewController: UIViewController {
    let session = PromiseURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var fetch: Promise<AnyObject>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        fetch = fetchLinks("all").when({ (json) in
            println(json)
        }).catch({ (error) in
            println(error)
        }).finally({ [unowned self] in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.fetch = nil
        })
    }
    
    func fetchLinks(reddit: String) -> Promise<AnyObject> {
        let url = NSURL(string: "http://reddit.com/r/" + reddit + ".json")
        
        return fetchJSON(url!).when({ [weak self] (data: NSData) -> Result<AnyObject> in
            return .Deferred(self!.parseJSON(data))
        })
    }

    func fetchJSON(url: NSURL) -> Promise<NSData> {
        let request = NSURLRequest(URL: url)
        return session.promise(request).when { (response, data) -> Result<NSData> in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    return .Failure(UnexpectedHTTPStatusCodeError())
                }
                
                let contentType = httpResponse.MIMEType != nil ? httpResponse.MIMEType : ""
                
                if contentType == "" {
                    return .Failure(MissingContentTypeError())
                }
                
                if contentType != "application/json" {
                    return .Failure(UnexpectedContentTypeError())
                }
                
                return .Success(data)
            } else {
                return .Failure(UnexpectedResponseError())
            }
        }
    }
    
    func parseJSON(data: NSData, options: NSJSONReadingOptions = NSJSONReadingOptions(0)) -> Promise<AnyObject> {
        let promise = Promise<AnyObject>()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak promise] in
            if let blockPromise = promise {
                var error: NSError?
                let value: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: options, error: &error)
                
                if value == nil {
                    if error == nil {
                        blockPromise.fulfill(NSNull())
                    } else {
                        blockPromise.reject(NSErrorWrapperError(cause: error!))
                    }
                } else {
                    blockPromise.fulfill(value!)
                }
            }
        }
        
        return promise
    }
}
