//
//  ListDiff.swift
//  Diffing
//
//  Created by Juan Alvarez on 4/19/17.
//  Copyright © 2017 Juan Alvarez. All rights reserved.
//

import Foundation

public enum ListDiffOption {
    /**
    Compare objects using pointer personality.
     
     - Warning: The objects in the lists must be of reference type.
    */
    case pointer
    
    /** Compare objects using `ListDiffable.isEqualToDiffable()`.*/
    case equality
}

public protocol ListDiffable {
    /**
     Returns a key that uniquely identifies the object.
     - Returns: A key that can be used to uniquely identify the object.
     
     - Note: Two objects may share the same identifier, but are not equal. A common pattern is to use the `NSObject`
     category for automatic conformance. However this means that objects will be identified on their
     pointer value so finding updates becomes impossible.
     
     - Warning: This value should never be mutated.
     */
    var diffIdentifier: AnyHashable { get }
    
    /**
     Returns whether the receiver and a given object are equal.
     
     - Parameter object: The object to be compared to the receiver.
     - Returns: `YES` if the receiver and object are equal, otherwise `NO`.
     */
    func isEqualToDiffable(object: ListDiffable) -> Bool
}

public enum ListDiff {
    /// Used to track data stats while diffing.
    /// We expect to keep a reference of entry, thus its declaration as (final) class.
    final class Entry {
        /// The number of times the data occurs in the old array
        var oldCounter: Int = 0
        
        /// The number of times the data occurs in the new array
        var newCounter: Int = 0
        
        /// The indexes of the data in the old array
        var oldIndexes: Stack<Int?> = Stack<Int?>()
        
        /// Flag marking if the data has been updated between arrays by equality check
        var updated: Bool = false
        
        /// Returns `true` if the data occur on both sides, `false` otherwise
        var occurOnBothSides: Bool {
            return self.newCounter > 0 && self.oldCounter > 0
        }
        
        func push(new index: Int?) {
            self.newCounter += 1
            self.oldIndexes.push(index)
        }
        
        func push(old index: Int?) {
            self.oldCounter += 1;
            self.oldIndexes.push(index)
        }
    }
    
    /// Track both the entry and the algorithm index. Default the index to `nil`
    struct Record {
        let entry: Entry
        var index: Int?
        
        init(_ entry: Entry) {
            self.entry = entry
            self.index = nil
        }
    }
    
    public struct MoveIndex: Equatable, Hashable {
        public let from: Int
        public let to: Int
        
        public var hashValue: Int {
            return from.hashValue ^ to.hashValue
        }
        
        public init(from: Int, to: Int) {
            self.from = from
            self.to = to
        }
        
        public static func ==(lhs: MoveIndex, rhs: MoveIndex) -> Bool {
            return lhs.from == rhs.from && lhs.to == rhs.to
        }
    }
    
    public struct MoveIndexPath: Equatable, Hashable {
        public let from: IndexPath
        public let to: IndexPath
        
        public var hashValue: Int {
            return from.hashValue ^ to.hashValue
        }
        
        public static func ==(lhs: MoveIndexPath, rhs: MoveIndexPath) -> Bool {
            return lhs.from == rhs.from && lhs.to == rhs.to
        }
    }
    
    public struct Result: CustomStringConvertible {
        public var inserts = IndexSet()
        public var updates = IndexSet()
        public var deletes = IndexSet()
        public var moves: [MoveIndex] = []
        
        public var oldIndexMap: [AnyHashable: Int] = [:]
        public var newIndexMap: [AnyHashable: Int] = [:]
        
        public var description: String {
            return "<Result \(self); \(self.inserts.count) inserts; \(self.deletes.count) deletes; \(self.updates.count) updates; \(self.moves.count) moves>"
        }
        
        public var hasChanges: Bool {
            return (self.inserts.count > 0) || (self.deletes.count > 0) || (self.updates.count > 0) || (self.moves.count > 0)
        }
        
        public var changeCount: Int {
            return self.inserts.count + self.deletes.count + self.updates.count + self.moves.count
        }
        
        public func validate(_ old: [ListDiffable], _ new: [ListDiffable]) -> Bool {
            return (old.count + self.inserts.count - self.deletes.count) == new.count
        }
        
        public func oldIndexFor(identifier: AnyHashable) -> Int? {
            return self.oldIndexMap[identifier]
        }
        
        public func newIndexFor(identifier: AnyHashable) -> Int? {
            return self.newIndexMap[identifier]
        }
        
        public func resultForBatchUpdates() -> Result {
            var newDeletes = self.deletes
            var newInserts = self.inserts
            
            var filteredUpdates = self.updates
            var filteredMoves = self.moves
            
            for (index, move) in self.moves.enumerated().reversed() {
                if filteredUpdates.contains(move.from) {
                    filteredMoves.remove(at: index)
                    filteredUpdates.remove(move.from)
                    
                    newDeletes.insert(move.from)
                    newInserts.insert(move.to)
                }
            }
            
            for (key, index) in self.oldIndexMap {
                if filteredUpdates.contains(index) {
                    newDeletes.insert(index)
                    
                    if let value = newIndexMap[key] {
                        newInserts.insert(value)
                    }
                }
            }
            
            return Result(inserts: newInserts,
                          updates: [],
                          deletes: newDeletes,
                          moves: filteredMoves,
                          oldIndexMap: self.oldIndexMap,
                          newIndexMap: self.newIndexMap)
        }
    }
    
    public struct IndexPathResult: CustomStringConvertible {
        public var inserts = Set<IndexPath>()
        public var deletes = Set<IndexPath>()
        public var updates = Set<IndexPath>()
        public var moves: [MoveIndexPath] = []
        
        fileprivate var oldIndexPathMap: [AnyHashable: IndexPath] = [:]
        fileprivate var newIndexPathMap: [AnyHashable: IndexPath] = [:]
        
        public var description: String {
            return "<IndexPathResult \(self); \(self.inserts.count) inserts; \(self.deletes.count) deletes; \(self.updates.count) updates; \(self.moves.count) moves>"
        }
        
        public var hasChanges: Bool {
            return (self.inserts.count > 0) || (self.deletes.count > 0) || (self.updates.count > 0) || (self.moves.count > 0)
        }
        
        public func validate(_ old: [ListDiffable], _ new: [ListDiffable]) -> Bool {
            return (old.count + self.inserts.count - self.deletes.count) == new.count
        }
        
        public func oldIndexFor(identifier: AnyHashable) -> IndexPath? {
            return self.oldIndexPathMap[identifier]
        }
        
        public func newIndexFor(identifier: AnyHashable) -> IndexPath? {
            return self.newIndexPathMap[identifier]
        }
        
        public func resultForBatchUpdates() -> IndexPathResult {
            var newDeletes = Set<IndexPath>(self.deletes)
            var newInserts = Set<IndexPath>(self.inserts)
            
            var filteredUpdates = Set<IndexPath>(self.updates)
            var filteredMoves = self.moves
            
            // convert move+update to delete+insert, respecting the from/to of the move
            for (index, move) in self.moves.enumerated().reversed() {
                if filteredUpdates.contains(move.from) {
                    filteredMoves.remove(at: index)
                    filteredUpdates.remove(move.from)
                    
                    newDeletes.insert(move.from)
                    newInserts.insert(move.to)
                }
            }
            
            // iterate all new identifiers. if its index is updated, delete from the old index and insert the new index
            for (key, indexPath) in self.oldIndexPathMap {
                if filteredUpdates.contains(indexPath) {
                    newDeletes.insert(indexPath)
                    
                    if let value = self.newIndexPathMap[key] {
                        newInserts.insert(value)
                    }
                }
            }
            
            return IndexPathResult(inserts: newInserts,
                                   deletes: newDeletes,
                                   updates: [],
                                   moves: filteredMoves,
                                   oldIndexPathMap: self.oldIndexPathMap,
                                   newIndexPathMap: self.newIndexPathMap)
        }
    }
    
    public static func diff<T: ListDiffable>(fromSection: Int, toSection: Int, old: [T], new: [T], option: ListDiffOption = .equality) -> IndexPathResult {
        let tuple = diffingRecords(old: old, new: new, option: option)
        
        let oldRecords = tuple.old
        let newRecords = tuple.new
        
        var result = IndexPathResult()
        
        // track offsets from deleted items to calculate where items have moved
        // iterate old array records checking for deletes
        // increment offset for each delete
        var runningOffset = 0
        let deleteOffsets = oldRecords.enumerated().map { (i, oldRecord) -> Int in
            let indexPath = IndexPath(item: i, section: fromSection)
            
            let deleteOffset = runningOffset
            // if the record index in the new array doesn't exist, its a delete
            if oldRecord.index == nil {
                result.deletes.insert(indexPath)
                
                runningOffset += 1
            }
            
            result.oldIndexPathMap[old[i].diffIdentifier] = indexPath
            
            return deleteOffset
        }
        
        // reset and track offsets from inserted items to calculate where items have moved
        runningOffset = 0
        
        /* let insertOffsets */_ = newRecords.enumerated().map { (i, newRecord) -> Int in
            let insertOffset = runningOffset
            
            if let oldIndex = newRecord.index {
                // note that an entry can be updated /and/ moved
                if newRecord.entry.updated {
                    let indexPath = IndexPath(item: oldIndex, section: fromSection)
                    
                    result.updates.insert(indexPath)
                }
                
                // calculate the offset and determine if there was a move
                // if the indexes match, ignore the index
                let deleteOffset = deleteOffsets[oldIndex]
                
                if (oldIndex - deleteOffset + insertOffset) != i {
                    let from = IndexPath(item: oldIndex, section: fromSection)
                    let to = IndexPath(item: i, section: toSection)
                    
                    let move = MoveIndexPath(from: from, to: to)
                    
                    result.moves.append(move)
                }
            } else { // add to inserts if the opposing index is nil
                let indexPath = IndexPath(item: i, section: toSection)
                
                result.inserts.insert(indexPath)
                
                runningOffset += 1
            }
            
            result.newIndexPathMap[new[i].diffIdentifier] = IndexPath(item: i, section: toSection)
            
            return insertOffset
        }
        
        assert(result.validate(old, new), "Sanity check failed applying \(result.inserts.count) inserts and \(result.deletes.count) deletes to old count \(old.count) equaling new count \(new.count)")
        
        return result
    }
    
    public static func diff<T: ListDiffable>(old: [T], new: [T], option: ListDiffOption = .equality) -> Result {
        let tuple = diffingRecords(old: old, new: new, option: option)
        
        let oldRecords = tuple.old
        let newRecords = tuple.new
        
        // storage for final indexes
        var result = Result()
        
        // track offsets from deleted items to calculate where items have moved
        // iterate old array records checking for deletes
        // increment offset for each delete
        var runningOffset = 0
        let deleteOffsets = oldRecords.enumerated().map { (i, oldRecord) -> Int in
            let deleteOffset = runningOffset
            // if the record index in the new array doesn't exist, its a delete
            if oldRecord.index == nil {
                result.deletes.insert(i)
                runningOffset += 1
            }
            result.oldIndexMap[old[i].diffIdentifier] = i
            return deleteOffset
        }
        
        //reset and track offsets from inserted items to calculate where items have moved
        runningOffset = 0
        /* let insertOffsets */_ = newRecords.enumerated().map { (i, newRecord) -> Int in
            let insertOffset = runningOffset
            if let oldIndex = newRecord.index {
                // note that an entry can be updated /and/ moved
                if newRecord.entry.updated {
                    result.updates.insert(oldIndex)
                }
                
                // calculate the offset and determine if there was a move
                // if the indexes match, ignore the index
                let deleteOffset = deleteOffsets[oldIndex]
                if (oldIndex - deleteOffset + insertOffset) != i {
                    result.moves.append(MoveIndex(from: oldIndex, to: i))
                }
            } else { // add to inserts if the opposing index is nil
                result.inserts.insert(i)
                runningOffset += 1
            }
            result.newIndexMap[new[i].diffIdentifier] = i
            return insertOffset
        }
        
        assert(result.validate(old, new), "Sanity check failed applying \(result.inserts.count) inserts and \(result.deletes.count) deletes to old count \(old.count) equaling new count \(new.count)")
        
        return result
    }
}

fileprivate extension ListDiff {
    
    static func diffingRecords<T: ListDiffable>(old: [T], new: [T], option: ListDiffOption) -> (new: [Record], old: [Record]) {
        // symbol table uses the old/new array `diffIdentifier` as the key and `Entry` as the value
        var table = Dictionary<AnyHashable, Entry>()
        
        // pass 1
        // create an entry for every item in the new array
        // increment its new count for each occurence
        // record `nil` for each occurence of the item in the new array
        var newRecords = new.map { (newRecord) -> Record in
            let key = newRecord.diffIdentifier
            if let entry = table[key] {
                // add `nil` for each occurence of the item in the new array
                entry.push(new: nil)
                
                return Record(entry)
            } else {
                let entry = Entry()
                // add `nil` for each occurence of the item in the new array
                entry.push(new: nil)
                table[key] = entry
                
                return Record(entry)
            }
        }
        
        // pass 2
        // update or create an entry for every item in the old array
        // increment its old count for each occurence
        // record the old index for each occurence of the item in the old array
        // MUST be done in descending order to respect the oldIndexes stack construction
        var oldRecords = old.enumerated().reversed().map { (i, oldRecord) -> Record in
            let key = oldRecord.diffIdentifier
            if let entry = table[key] {
                // push the old indices where the item occured onto the index stack
                entry.push(old: i)
                
                return Record(entry)
            } else {
                let entry = Entry()
                // push the old indices where the item occured onto the index stack
                entry.push(old: i)
                table[key] = entry
                
                return Record(entry)
            }
        }
        
        // pass 3
        // handle data that occurs in both arrays
        newRecords.enumerated().filter { $1.entry.occurOnBothSides }.forEach { (i, newRecord) in
            let entry = newRecord.entry
            // grab and pop the top old index. if the item was inserted this will be nil
            assert(!entry.oldIndexes.isEmpty, "Old indexes is empty while iterating new item \(i). Should have nil")
            guard let oldIndex = entry.oldIndexes.pop() else {
                return
            }
            if oldIndex < old.count {
                let n = new[i]
                let o = old[oldIndex]
                
                switch option {
                case .pointer:
                    // flag the entry as updated if the pointers are not the same
                    if type(of: n) is AnyClass && type(of: o) is AnyClass {
                        if (n as AnyObject) !== (o as AnyObject) {
                            entry.updated = true
                        }
                    } else {
                        assertionFailure("Using pointer option is only available for reference types")
                    }
                case .equality:
                    // use ListDiffable.isEqualToDiffable() between both version of data to see if anything has changed
                    // skip the equality check if both indexes point to the same object
                    if !n.isEqualToDiffable(object: o) {
                        entry.updated = true
                    }
                }
            }
            
            // if an item occurs in the new and old array, it is unique
            // assign the index of new and old records to the opposite index (reverse lookup)
            newRecords[i].index = oldIndex
            oldRecords[oldIndex].index = i
        }
        
        return (new: newRecords, old: oldRecords)
    }
}
