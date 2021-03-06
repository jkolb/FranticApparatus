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

public struct NetworkResult {
    public let response: URLResponse
    public let data: Data
}

public enum NetworkError : Error {
    case unexpectedData(Data)
    case unexpectedResponse(URLResponse)
    case unexpectedStatusCode(Int)
    case unexpectedContentType(String)
}

public protocol NetworkLayer : class {
    func requestData(_ request: URLRequest) -> Promise<NetworkResult>
}

public final class SimpleURLSessionNetworkLayer : NetworkLayer {
    private let session: URLSession
    
    public init() {
        let sessionConfiguration = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    public func requestData(_ request: URLRequest) -> Promise<NetworkResult> {
        return Promise<NetworkResult> { (fulfill, reject) in
            session.dataTask(with: request, completionHandler: { (data, response, error) in
                if let error = error {
                    reject(error)
                }
                else if let data = data, let response = response {
                    fulfill(NetworkResult(response: response, data: data))
                }
                else {
                    fatalError("Unexpected")
                }
            }).resume()
        }
    }
}
