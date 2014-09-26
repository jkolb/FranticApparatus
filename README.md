# [FranticApparatus 2.0](https://github.com/jkolb/FranticApparatus)

#### A Promises/A+ implementation for Swift

## Examples

#### A chain of promises that fetches some JSON from a URL, parses the JSON into an NSDictionary, and then maps the NSDictionay into an array of Link objects. All of these tasks occur on separate threads but the callbacks occur on the main thread.

    func fetchLinks(reddit: String) -> Promise<[Link]> {
        let url = NSURL(string: baseURL + "/r/" + reddit + ".json")
        
        return fetchJSON(url).when({ (data: NSData) -> Result<NSDictionary> in
            return .Deferred(parseJSON(data))
        }).when({ (json: NSDictionary) -> Result<[Link]> in
            return .Deferred(mapLinks(json))
        })
    }

#### An example of how to use the fetchLinks function defined above.

    UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        
    fetch = reddit.fetchLinks("all").when({ (links) in
		println(links)
    }).catch({ (error) in
		println(error)
    }).finally({ [unowned self] in
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false;
        self.fetch = nil
    })

#### An example of how to create a simple promise that returns data from a URL get request.

    func fetchJSON(url: NSURL) -> Promise<NSData> {
        let promise = Promise<NSData>()
        
        dataTask = session.dataTaskWithURL(url) { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if error != nil {
                promise.reject(NSErrorWrapperError(cause: error))
                return
            }
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    promise.reject(UnexpectedHTTPStatusCodeError())
                    return
                }
                
                let contentType = httpResponse.MIMEType != nil ? httpResponse.MIMEType : ""
                
                if contentType == "" {
                    promise.reject(MissingContentTypeError())
                    return
                }
                
                if contentType != "application/json" {
                    promise.reject(UnexpectedContentTypeError())
                    return
                }
                
                promise.fulfill(data)
            } else {
                promise.reject(UnexpectedResponseError())
            }
        }
        dataTask.resume()
        
        return promise
    }

#### An example of a promise that returns an NSDictionary from JSON data.

    func parseJSON(data: NSData, options: NSJSONReadingOptions = NSJSONReadingOptions(0)) -> Promise<NSDictionary> {
        let promise = Promise<JSONValue>()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak promise] in
            if let blockPromise = promise {
                var error: NSError?
                let value: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: options, error: &error)
                
                if value == nil {
                    if error == nil {
                        blockPromise.fulfill(InvalidJSONError())
                    } else {
                        blockPromise.reject(NSErrorWrapperError(cause: error!))
                    }
                } else {
                    blockPromise.fulfill(value! as NSDictionary) // Unsafe cast!
                }
            }
        }
        
        return promise
    }

## Contact

[Justin Kolb](mailto:justin.kolb@franticapparatus.net)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
