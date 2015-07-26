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

enum ExampleError : ErrorType {
    case UnexpectedResponse
    case UnexpectedHTTPStatusCode
    case MissingContentType
    case UnexpectedContentType
    case UnexpectedJSON
    case LinkListingParse
}

class ViewController: UIViewController {
    let session: URLPromiseFactory = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: SimpleURLSessionDataDelegate(), delegateQueue: NSOperationQueue())
    var promise: Promise<NSDictionary>?
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshData()
    }
    
    func refreshData() {
        self.showActivity()
        
        promise = fetchLinks("all").then({ json in
            print(json, appendNewline: true)
        }).handle({ error in
            print(error, appendNewline: true)
        }).finally(self, { strongSelf in
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
    
    func fetchLinks(reddit: String) -> Promise<NSDictionary> {
        let url = NSURL(string: "https://reddit.com/r/" + reddit + ".json")
        
        return fetchJSON(url!).then(self, { (strongSelf, data) -> Result<NSDictionary> in
            return .Deferred(strongSelf.parseJSON(data))
        })
    }

    func fetchJSON(url: NSURL) -> Promise<NSData> {
        let request = NSURLRequest(URL: url)
        
        return session.promise(request).then { (response) -> Result<NSData> in
            if let httpResponse = response.metadata as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    return .Failure(ExampleError.UnexpectedHTTPStatusCode)
                }
                
                let contentType = httpResponse.MIMEType ?? ""
                
                if contentType == "" {
                    return .Failure(ExampleError.MissingContentType)
                }
                
                if contentType != "application/json" {
                    return .Failure(ExampleError.UnexpectedContentType)
                }
                
                return .Success(response.data)
            } else {
                return .Failure(ExampleError.UnexpectedResponse)
            }
        }
    }
    
    func parseJSON(data: NSData, options: NSJSONReadingOptions = []) -> Promise<NSDictionary> {
        return Promise<NSDictionary> { (fulfill, reject, isCancelled) in
            GCDQueue.globalPriorityDefault().dispatch {
                do {
                    let value: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data, options: options)
                    
                    if let dictionary = value as? NSDictionary {
                        fulfill(dictionary)
                    } else {
                        reject(ExampleError.UnexpectedJSON)
                    }
                }
                catch {
                    reject(error)
                }
            }
        }
    }
}
