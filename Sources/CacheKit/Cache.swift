//
//  Cache.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/24.
//

import Foundation

public typealias DiskCaching = CodableObjectStoring & InitializableFromURL
public typealias MemoryCaching = AnyObjectStoring

open class Cache:
    CodableObjectStoring,
    InitializableFromURL
{
    public func remove(_ key: Key) throws {
        try memoryCache.remove(key)
        try diskCache.remove(key)
    }
    
    public func remove(_ keys: [Key]) throws {
        try memoryCache.remove(keys)
        try diskCache.remove(keys)
    }
    
    public func removeAll() throws {
        try memoryCache.removeAll()
        try diskCache.removeAll()
    }
    
    public func contains(_ key: String) -> Bool {
        memoryCache.contains(key) || diskCache.contains(key)
    }
    
    public func object<Object: Codable>(by key: Key) -> Object? {
        memoryCache.object(by: key) ?? diskCache.object(by: key)
    }
    
    public func objects<Object: Codable>(by keys: [Key]) -> [Object?] {
        keys.map {
            memoryCache.object(by: $0) ?? diskCache.object(by: $0)
        }
    }
    
    public func set<Object: Codable>(_ object: Object, by key: Key) throws {
        try diskCache.set(object, by: key)
        memoryCache.set(object, by: key)
    }
    
    public func set<Object: Codable>(_ keyValuePairs: [(Key, Object)]) throws {
        try diskCache.set(keyValuePairs)
        memoryCache.set(keyValuePairs)
    }
    
    public func nsObject<Object: NSCodable>(by key: Key) -> Object? {
        memoryCache.object(by: key) ?? diskCache.nsObject(by: key)
    }
    
    public func nsObjects<Object: NSCodable>(by keys: [Key]) -> [Object?] {
        keys.map {
            memoryCache.object(by: $0) ?? diskCache.nsObject(by: $0)
        }
    }
    
    public func nsSet<Object: NSCodable>(_ object: Object, by key: Key) throws {
        try diskCache.nsSet(object, by: key)
        memoryCache.set(object, by: key)
    }
    
    public func nsSet<Object: NSCodable>(_ keyValuePairs: [(Key, Object)]) throws {
        try diskCache.nsSet(keyValuePairs)
        memoryCache.set(keyValuePairs)
    }
    
    let name: String
    let memoryCache: MemoryCaching
    let diskCache: DiskCaching
    
    required public convenience init(url: URL) throws {
        try self.init(url: url, memoryCache: nil)
    }
    
    public init(
        url: URL,
        memoryCache: MemoryCaching? = nil,
        diskCache: DiskCaching? = nil
    ) throws {
        assert(url.isFileURL, "URL of a Cache must be a file URL.")
        let name = url.lastPathComponent
        self.name = name
        self.memoryCache = memoryCache ?? MemoryCache(name: name)
        self.diskCache = try diskCache ?? DefaultDiskCache(url: url)
    }
}

extension Cache {
    public enum Error: Swift.Error {
        public enum InitializationError: Swift.Error {
            case diskCache(DatabaseError)
        }
        
        case initialization(_ error: InitializationError)
    }
}
