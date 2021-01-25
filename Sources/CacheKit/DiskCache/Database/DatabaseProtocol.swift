//
//  DatabaseProtocol.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/20.
//

import Foundation

public protocol DatabaseProtocol: InitializableFromURL {
    /// Representation of the entity.
    associatedtype Object
    /// Objects to return in the `lessRecentlyAccessedObjects`
    /// function. You can return a lazy iterator for performance.
    associatedtype LessAccessedObjects: DatabaseObjectSequence
    where LessAccessedObjects.Element == Object
    /// Number of records.
    var count: Int { get }
    /// Sum of the `size` value of all the records.
    var size: Int { get }
    /// All the records, ordered by the last time it was accessed. You can return a lazy iterator.
    ///
    /// - Parameter limit: If set, the method returns limited number of objects at most.
    func lessRecentlyAccessedObjects(limit: Int) -> LessAccessedObjects
    /// Add a record.
    func insert(_ object: Object) throws
    /// Add records.
    func insert(_ objects: [Object]) throws
    /// Retrieve a record by key.
    func object(by key: String) -> Object?
    /// Retrieve some records by keys.
    func objects(by keys: [String]) -> [Object?]
    /// Remove a record by key.
    func remove(by key: String) throws
    /// Delete some records by keys.
    func remove(by keys: [String]) throws
    /// Delete all records.
    func removeAll() throws
}

/// Posible errors of `DatabaseProtocol` instances.
public enum DatabaseError: Error {
    /// Failed to initialize the database, with the underlying error if there is one.
    case initializationFailed(_ error: Error?)
    /// Failed to insert an object.
    case insertionFailed(_ error: Error?)
    /// Failed to delete one or more objects.
    case deletionFailed(_ error: Error?)
}
