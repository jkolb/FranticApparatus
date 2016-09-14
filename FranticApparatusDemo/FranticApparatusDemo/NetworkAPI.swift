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
    fileprivate let networkLayer: NetworkLayer
    fileprivate let dispatcher: Dispatcher
    
    public init(dispatcher: Dispatcher, networkLayer: NetworkLayer) {
        self.dispatcher = dispatcher
        self.networkLayer = networkLayer
    }
    
    public func requestJSONObjectForURL(_ url: URL) -> Promise<NSDictionary> {
        return requestJSON(URLRequest(url: url)).thenOn(dispatcher, withObject: self) { (api, data) -> Promise<NSDictionary> in
            return api.parseJSONData(data)
        }
    }
    
    public func requestImageForURL(_ url: URL) -> Promise<UIImage> {
        return PromiseMaker<NetworkAPI, UIImage>.makeUsing(dispatcher: dispatcher, context: self) { (make) in
            make { (context) in
                return context.requestImage(URLRequest(url: url))
            }.then { (context, data) in
                return context.parseImageData(data)
            }
        }
    }

    fileprivate func parseJSONData(_ data: Data) -> Promise<NSDictionary> {
        return Promise<NSDictionary> { (fulfill, reject, isCancelled) in
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                
                if let dictionary = object as? NSDictionary {
                    fulfill(dictionary)
                }
                else {
                    reject(NetworkError.unexpectedData(data))
                }
            }
            catch {
                reject(error)
            }
        }
    }
    
    fileprivate func parseImageData(_ data: Data) -> Promise<UIImage> {
        return Promise<UIImage> { (fulfill, reject, isCancelled) in
            if let image = UIImage(data: data) {
                fulfill(image)
            }
            else {
                reject(NetworkError.unexpectedData(data))
            }
        }
    }
    
    fileprivate func requestJSON(_ request: URLRequest) -> Promise<Data> {
        return requestData(request, allowedStatusCodes: [200], allowedContentTypes: ["application/json"])
    }

    fileprivate func requestImage(_ request: URLRequest) -> Promise<Data> {
        return requestData(request, allowedStatusCodes: [200], allowedContentTypes: ["image/jpeg", "image/png"])
    }
    
    fileprivate func requestData(_ request: URLRequest, allowedStatusCodes: [Int], allowedContentTypes: [String]) -> Promise<Data> {
        return networkLayer.requestData(request).thenOn(dispatcher) { (response, data) -> Data in
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unexpectedResponse(response)
            }
            
            guard Set<Int>(allowedStatusCodes).contains(httpResponse.statusCode) else {
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }
            
            let contentType = httpResponse.mimeType ?? ""
            
            guard Set<String>(allowedContentTypes).contains(contentType) else {
                throw NetworkError.unexpectedContentType(contentType)
            }
            
            return data
        }
    }
}
