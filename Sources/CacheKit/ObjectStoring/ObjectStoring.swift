//
//  KeyValueStorageProtocol.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/1.
//

import Foundation

/// Store and retrieve objects by keys.
///
/// This protocol is not intended to be used directly, since it lacks the basic storing and retrieving functions,
/// that are defined in the `AnyObjectStoring` and `CodableObjectStoring` protocols.
public protocol ObjectStoring {
    /// Use `String` as key.
    typealias Key = String
    
    /// If a key already exists.
    func contains(_ key: Key) -> Bool
    
    /// Remove an object by its key.
    func remove(_ key: Key) throws
    
    /// Remove objects by keys.
    func remove(_ keys: [Key]) throws
    
    /// Remove all the objects.
    func removeAll() throws
}
