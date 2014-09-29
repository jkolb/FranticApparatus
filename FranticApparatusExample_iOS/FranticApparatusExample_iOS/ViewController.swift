//
//  ViewController.swift
//  FranticApparatusExample_iOS
//
//  Created by Justin Kolb on 9/28/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import UIKit
import FranticApparatus

class UnexpectedResponseError : Error {}
class UnexpectedHTTPStatusCodeError : Error {}
class MissingContentTypeError : Error {}
class UnexpectedContentTypeError : Error {}
class LinkListingParseError : Error {}
class NSErrorWrapperError : Error {
    let cause: NSError
    
    init(cause: NSError) {
        self.cause = cause
    }
}

class ViewController: UIViewController {
    let session = PromiseURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var fetch: Promise<AnyObject>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        
        fetch = fetchLinks("all").when({ (json) in
            println(json)
        }).catch({
            switch $0 {
            case is UnexpectedContentTypeError:
                println("Unexpected content type")
            default:
                println($0)
                println("Default error")
            }
        }).finally({ [unowned self] in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false;
            self.fetch = nil
        })
    }
    
    func fetchLinks(reddit: String) -> Promise<AnyObject> {
        let url = NSURL(string: "http://reddit.com/r/" + reddit + ".json")
        
        return fetchJSON(url).when({ [weak self] (data: NSData) -> Result<AnyObject> in
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
