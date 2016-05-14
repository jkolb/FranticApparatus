//
//  ApplicationNetworkActivityIndicator.swift
//  FranticApparatusDemo
//
//  Created by Justin Kolb on 5/14/16.
//  Copyright © 2016 Justin Kolb. All rights reserved.
//

import UIKit

public final class ApplicationNetworkActvityIndicator : NetworkActivityIndicator {
    private var activityVisibleCount: Int

    public init() {
        self.activityVisibleCount = 0
    }
    
    deinit {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    public func show() {
        if activityVisibleCount == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            activityVisibleCount = 1
        }
        else if activityVisibleCount < Int.max {
            activityVisibleCount += 1
        }
    }
    
    public func hide() {
        if activityVisibleCount == 1 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            activityVisibleCount = 0
        }
        else if activityVisibleCount > 0 {
            activityVisibleCount -= 1
        }
    }
}
