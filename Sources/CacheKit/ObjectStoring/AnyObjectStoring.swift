//
//  AnyObjectStoring.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/29.
//

import Foundation

/// Store and retrieve objects by keys.
///
/// Supporting batch retrieval and insertion gives you a chance to do I/O optimizations.
/// Hence, try not to redirect calls that read / write a single object to functions that handle
/// multiple objects, doing so creates unnecessary arrays, which is harmful to performance.
public protocol AnyObjectStoring: ObjectStoring {
    /// Retrieve an object by key.
    ///
    /// - Parameter key: Key of the object.
    func object<Object>(by key: Key) -> Object?
    
    /// Retrieve objects by keys.
    ///
    /// - Parameter keys: Keys of the objects.
    func objects<Object>(by keys: [Key]) -> [Object?]
    
    /// Insert an object by key.
    ///
    /// - Parameters:
    ///     - object: The object to insert.
    ///     - key: The key of the object.
    func set<Object>(_ object: Object, by key: Key)
    
    /// Insert objects by keys.
    ///
    /// - Parameters:
    ///     - keyValuePairs: The object and key pairs to insert.
    func set<Object>(_ keyValuePairs: [(Key, Object)])
}
