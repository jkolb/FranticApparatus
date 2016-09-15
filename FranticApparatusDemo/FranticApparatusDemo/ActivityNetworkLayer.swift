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

public final class ActivityNetworkLayer : NetworkLayer {
    fileprivate let dispatcher: Dispatcher
    fileprivate let networkLayer: NetworkLayer
    fileprivate let networkActivityIndicator: NetworkActivityIndicator
    
    public init(dispatcher: Dispatcher, networkLayer: NetworkLayer, networkActivityIndicator: NetworkActivityIndicator) {
        self.dispatcher = dispatcher
        self.networkLayer = networkLayer
        self.networkActivityIndicator = networkActivityIndicator
    }
    
    public func requestData(_ request: URLRequest) -> Promise<NetworkResult> {
        return PromiseMaker.makeUsing(dispatcher: dispatcher, context: self) { (make) in
            make { (context) in
                context.networkActivityIndicator.show()
                return context.networkLayer.requestData(request)
            }.finally { (context) in
                context.networkActivityIndicator.hide()
            }
        }
    }
}
