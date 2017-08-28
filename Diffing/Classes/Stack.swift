//
//  Stack.swift
//  Diffing
//
//  Created by Juan Alvarez on 4/19/17.
//  Copyright © 2017 Juan Alvarez. All rights reserved.
//

import Foundation

struct Stack<Element> {
    var items: [Element] = []
    
    var isEmpty: Bool {
        return self.items.isEmpty
    }
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element {
        return items.removeLast()
    }
}
