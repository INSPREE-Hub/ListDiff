//
//  Numbers+Diffable.swift
//  Diffing
//
//  Created by Juan Alvarez on 4/19/17.
//  Copyright © 2017 Juan Alvarez. All rights reserved.
//

import Foundation

extension Int: ListDiffable {
    
    public var diffIdentifier: AnyHashable {
        return self
    }
    
    public func isEqualToDiffable(object: ListDiffable) -> Bool {
        guard let other = object as? Int else {
            return false
        }
        
        return self == other
    }
}

extension Float: ListDiffable {
    
    public var diffIdentifier: AnyHashable {
        return self
    }
    
    public func isEqualToDiffable(object: ListDiffable) -> Bool {
        guard let other = object as? Float else {
            return false
        }
        
        return self == other
    }
}

extension Double: ListDiffable {
    
    public var diffIdentifier: AnyHashable {
        return self
    }
    
    public func isEqualToDiffable(object: ListDiffable) -> Bool {
        guard let other = object as? Double else {
            return false
        }
        
        return self == other
    }
}
