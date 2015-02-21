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
    let session: URLPromiseFactory = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: SimpleURLSessionDataDelegate(), delegateQueue: NSOperationQueue())
    var promise: Promise<AnyObject>?
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshData()
    }
    
    func refreshData() {
        self.showActivity()
        
        promise = fetchLinks("all").then({ (json) in
            println(json)
        }).catch({ (error) in
            println(error)
        }).finally(self, { (strongSelf) in
            strongSelf.hideActivity()
            strongSelf.promise = nil
        })
    }
    
    func showActivity() {
        activityIndicator.sizeToFit()
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    func fetchLinks(reddit: String) -> Promise<AnyObject> {
        let url = NSURL(string: "http://reddit.com/r/" + reddit + ".json")
        
        return fetchJSON(url!).then(self, { (strongSelf, data) -> Result<AnyObject> in
            return Result(strongSelf.parseJSON(data))
        })
    }

    func fetchJSON(url: NSURL) -> Promise<NSData> {
        let request = NSURLRequest(URL: url)
        return session.promise(request).then { (response) -> Result<NSData> in
            if let httpResponse = response.metadata as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    return Result(UnexpectedHTTPStatusCodeError())
                }
                
                let contentType = httpResponse.MIMEType ?? ""
                
                if contentType == "" {
                    return Result(MissingContentTypeError())
                }
                
                if contentType != "application/json" {
                    return Result(UnexpectedContentTypeError())
                }
                
                return Result(response.data)
            } else {
                return Result(UnexpectedResponseError())
            }
        }
    }
    
    func parseJSON(data: NSData, options: NSJSONReadingOptions = NSJSONReadingOptions(0)) -> Promise<AnyObject> {
        return Promise<AnyObject> { (fulfill, reject, isCancelled) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var error: NSError?
                let value: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: options, error: &error)
                
                if value == nil {
                    if error == nil {
                        fulfill(NSNull())
                    } else {
                        reject(NSErrorWrapperError(cause: error!))
                    }
                } else {
                    fulfill(value!)
                }
            }
        }
    }
}
