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

import UIKit

public final class ApplicationNetworkActvityIndicator : NetworkActivityIndicator {
    public static let shared = ApplicationNetworkActvityIndicator()
    private var activityVisibleCount: Int

    public init() {
        self.activityVisibleCount = 0
    }
    
    deinit {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    public func show() {
        if self.activityVisibleCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.activityVisibleCount = 1
        }
        else if self.activityVisibleCount < Int.max {
            self.activityVisibleCount += 1
        }
    }
    
    public func hide() {
        if self.activityVisibleCount == 1 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.activityVisibleCount = 0
        }
        else if self.activityVisibleCount > 0 {
            self.activityVisibleCount -= 1
        }
    }
}
