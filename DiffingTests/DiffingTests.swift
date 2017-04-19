//
//  DiffingTests.swift
//  DiffingTests
//
//  Created by Juan Alvarez on 4/19/17.
//  Copyright © 2017 Juan Alvarez. All rights reserved.
//

import XCTest
@testable import Diffing

class SwiftClass: ListDiffable {
    
    let id: Int
    let value: String
    
    var diffIdentifier: AnyHashable {
        return id
    }
    
    init(id: Int, value: String) {
        self.id = id
        self.value = value
    }
    
    func isEqualToDiffable(object: ListDiffable) -> Bool {
        guard let object = object as? SwiftClass else {
            return false
        }
        
        return id == object.id && value == object.value
    }
}

class DiffingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDiffingStrings() {
        let o = ["a", "b", "c"]
        let n = ["a", "c", "d"]
        
        let result = ListDiff.diff(old: o, new: n, option: .equality)
        
        XCTAssertEqual(result.deletes, IndexSet(integer: 1))
        XCTAssertEqual(result.inserts, IndexSet(integer: 2))
        XCTAssertEqual(result.moves.count, 0)
        XCTAssertEqual(result.updates.count, 0)
    }
    
    func testDiffingNumbers() {
        let o = [0, 1, 2]
        let n = [0, 2, 4]
        
        let result = ListDiff.diff(old: o, new: n, option: .equality)
        
        XCTAssertEqual(result.deletes, IndexSet(integer: 1))
        XCTAssertEqual(result.inserts, IndexSet(integer: 2))
        XCTAssertEqual(result.moves.count, 0)
        XCTAssertEqual(result.updates.count, 0)
    }
    
    func testDiffingSwiftClass() {
        let o = [SwiftClass(id: 0, value: "a"), SwiftClass(id: 1, value: "b"), SwiftClass(id: 2, value: "c")]
        let n = [SwiftClass(id: 0, value: "a"), SwiftClass(id: 2, value: "c"), SwiftClass(id: 4, value: "d")]
        
        let result = ListDiff.diff(old: o, new: n, option: .equality)
        
        XCTAssertEqual(result.deletes, IndexSet(integer: 1))
        XCTAssertEqual(result.inserts, IndexSet(integer: 2))
        XCTAssertEqual(result.moves.count, 0)
        XCTAssertEqual(result.updates.count, 0)
    }
    
    func testDiffingSwiftClassPointerComparison() {
        let o = [SwiftClass(id: 0, value: "a"), SwiftClass(id: 1, value: "b"), SwiftClass(id: 2, value: "c")]
        let n = [SwiftClass(id: 0, value: "a"), SwiftClass(id: 2, value: "c"), SwiftClass(id: 4, value: "d")]
        
        let result = ListDiff.diff(old: o, new: n, option: .pointer)
        
        XCTAssertEqual(result.deletes, IndexSet(integer: 1))
        XCTAssertEqual(result.inserts, IndexSet(integer: 2))
        XCTAssertEqual(result.moves.count, 0)
        XCTAssertEqual(result.updates.count, 2)
    }
    
    func testDiffingSwiftClassWithUpdates() {
        let o = [SwiftClass(id: 0, value: "a"), SwiftClass(id: 1, value: "b"), SwiftClass(id: 2, value: "c")]
        let n = [SwiftClass(id: 0, value: "b"), SwiftClass(id: 1, value: "b"), SwiftClass(id: 2, value: "b")]
        
        let result = ListDiff.diff(old: o, new: n, option: .equality)
        
        XCTAssertEqual(result.deletes.count, 0)
        XCTAssertEqual(result.inserts.count, 0)
        XCTAssertEqual(result.moves.count, 0)
        XCTAssertEqual(result.updates.count, 2)
    }
}
