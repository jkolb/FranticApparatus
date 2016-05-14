/*
 The MIT License (MIT)
 
 Copyright (c) 2016 Justin Kolb
 
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

import Foundation
import FranticApparatus
import UIKit

public final class NetworkAPI {
    private let networkLayer: NetworkLayer
    private let dispatcher: Dispatcher
    
    public init(dispatcher: Dispatcher, networkLayer: NetworkLayer) {
        self.dispatcher = dispatcher
        self.networkLayer = networkLayer
    }
    
    public func requestJSONObjectForURL(url: NSURL) -> Promise<NSDictionary> {
        return requestJSON(NSURLRequest(URL: url)).thenOn(dispatcher, withObject: self) { (api, data) -> Promise<NSDictionary> in
            return api.parseJSONData(data)
        }
    }
    
    public func requestImageForURL(url: NSURL) -> Promise<UIImage> {
        return requestImage(NSURLRequest(URL: url)).thenOn(dispatcher, withObject: self) { (api, data) -> Promise<UIImage> in
            return api.parseImageData(data)
        }
    }

    private func parseJSONData(data: NSData) -> Promise<NSDictionary> {
        return Promise<NSDictionary> { (fulfill, reject, isCancelled) in
            do {
                let object = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                
                if let dictionary = object as? NSDictionary {
                    fulfill(dictionary)
                }
                else {
                    reject(NetworkError.UnexpectedData(data))
                }
            }
            catch {
                reject(error)
            }
        }
    }
    
    private func parseImageData(data: NSData) -> Promise<UIImage> {
        return Promise<UIImage> { (fulfill, reject, isCancelled) in
            if let image = UIImage(data: data) {
                fulfill(image)
            }
            else {
                reject(NetworkError.UnexpectedData(data))
            }
        }
    }
    
    private func requestJSON(request: NSURLRequest) -> Promise<NSData> {
        return requestData(request, allowedStatusCodes: [200], allowedContentTypes: ["application/json"])
    }

    private func requestImage(request: NSURLRequest) -> Promise<NSData> {
        return requestData(request, allowedStatusCodes: [200], allowedContentTypes: ["image/jpeg", "image/png"])
    }
    
    private func requestData(request: NSURLRequest, allowedStatusCodes: [Int], allowedContentTypes: [String]) -> Promise<NSData> {
        return networkLayer.requestData(request).thenOn(dispatcher, { (response, data) -> NSData in
            guard let httpResponse = response as? NSHTTPURLResponse else {
                throw NetworkError.UnexpectedResponse(response)
            }
            
            guard Set<Int>(allowedStatusCodes).contains(httpResponse.statusCode) else {
                throw NetworkError.UnexpectedStatusCode(httpResponse.statusCode)
            }
            
            let contentType = httpResponse.MIMEType ?? ""
            
            guard Set<String>(allowedContentTypes).contains(contentType) else {
                throw NetworkError.UnexpectedContentType(contentType)
            }
            
            return data
        })
    }
}
