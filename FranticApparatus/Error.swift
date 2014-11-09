//
//  Error.swift
//  FranticApparatus
//
//  Created by Justin Kolb on 9/30/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import Foundation

public class Error : Printable {
    public let message: String
    
    public init(message: String = "") {
        self.message = message
    }
    
    public var description: String {
        return reflect(self).summary + ": " + message
    }
}

public class NSErrorWrapperError : Error, Printable {
    public let cause: NSError
    
    public init(cause: NSError) {
        self.cause = cause
        super.init(message: cause.description)
    }
}

public class OutOfMemoryError : Error { }

public class ContextUnavailableError : Error { }
