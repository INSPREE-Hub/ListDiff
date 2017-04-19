//
//  String+Diffable.swift
//  Diffing
//
//  Created by Juan Alvarez on 4/19/17.
//  Copyright © 2017 Juan Alvarez. All rights reserved.
//

import Foundation

extension String: ListDiffable {
    
    public var diffIdentifier: AnyHashable {
        return self
    }
    
    public func isEqualToDiffable(object: ListDiffable) -> Bool {
        guard let other = object as? String else {
            return false
        }
        
        return self == other
    }
}
