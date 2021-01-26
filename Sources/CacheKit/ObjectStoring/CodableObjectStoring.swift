//
//  CodableObjectStoring.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/29.
//

import Foundation

/// Store and retrieve `Codable` objects by keys.
///
/// Supporting batch retrieval and insertion gives you a chance for I/O optimizations.
/// Try not to redirect calls that read / write a single object to functions that handle
/// multiple objects, doing so creates unnecessary arrays, which is harmful to performance.
public protocol CodableObjectStoring: ObjectStoring {
    /// Retrieve a Swift `Codable` object by key.
    ///
    /// This method retrieves the object you stored with `set(_:by:)`.
    ///
    /// - Parameter key: Key of the object.
    ///
    /// - Returns: The object corresponding to the key. Nil if not exists or some error occurred.
    ///     Errors happended during the reading process are not thrown, but logged.
    func object<Object: Codable>(by key: Key) -> Object?
    
    /// Retrieve multiple Swift `Codable` objects by keys.
    ///
    /// This method retrieves the objects you stored with `set(_:by:)`.
    ///
    /// - Parameter key: Keys of the objects.
    ///
    /// - Returns: Objects corresponding to the keys you provided, in order. Element is nil if it
    ///     doesn't exist. Errors happended during the reading process are not thrown, but logged.
    func objects<Object: Codable>(by keys: [Key]) -> [Object?]
    
    /// Retrieve an `NSSucureCoding` `NSObject` by key.
    ///
    /// This method retrieves the object you stored with `nsSet(_:by:)`.
    ///
    /// - Parameter key: Key of the object.
    ///
    /// - Returns: The object corresponding to the key. Nil if not exists or some error occurred.
    ///     Errors happended during the reading process are not thrown, but logged.
    func nsObject<Object: NSCodable>(by key: Key) -> Object?
    
    /// Retrieve multiple `NSSucureCoding` `NSObject`s by keys.
    ///
    /// This method retrieves the objects you stored with `nsSet(_:by:)`.
    ///
    /// - Parameter key: Keys of the objects.
    ///
    /// - Returns: Objects corresponding to the keys you provided, in order. Element is nil if it
    ///     doesn't exist. Errors happended during the reading process are not thrown, but logged.
    func nsObjects<Object: NSCodable>(by keys: [Key]) -> [Object?]
    
    /// Insert a Swift `Codable` object by key.
    ///
    /// - Parameters
    ///     - object: The object to store.
    ///     - key: Key of the object.
    ///
    /// - Throws:
    ///     - `CacheKit.Cache.Error` by default.
    ///     - `CacheKit.DiskCacheError` if you are using `DiskCache` directly.
    func set<Object: Codable>(_ object: Object, by key: Key) throws
    
    /// Insert multiple Swift `Codable` objects by keys.
    ///
    /// - Parameter keyValuePairs: Object and its key, in tuple.
    ///
    /// - Throws:
    ///     - `CacheKit.Cache.Error` by default.
    ///     - `CacheKit.DiskCacheError` if you are using `DiskCache` directly.
    func set<Object: Codable>(_ keyValuePairs: [(Key, Object)]) throws
    
    /// Insert an `NSSecureCoding` `NSObject` by key.
    /// 
    /// - Parameters
    ///     - object: The object to store.
    ///     - key: Key of the object.
    ///
    /// - Throws:
    ///     - `CacheKit.Cache.Error` by default.
    ///     - `CacheKit.DiskCacheError` if you are using `DiskCache` directly.
    func nsSet<Object: NSCodable>(_ object: Object, by key: Key) throws
    
    /// Insert multiple `NSSucureCoding` `NSObject`s by keys.
    ///
    /// - Parameter keyValuePairs: Array of (Object, Key).
    ///
    /// - Throws:
    ///     - `CacheKit.Cache.Error` by default.
    ///     - `CacheKit.DiskCacheError` if you are using `DiskCache` directly.
    func nsSet<Object: NSCodable>(_ keyValuePairs: [(Key, Object)]) throws
}
