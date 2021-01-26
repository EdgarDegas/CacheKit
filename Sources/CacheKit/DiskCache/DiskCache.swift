//
//  DiskCache.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/24.
//

import Foundation
import class UIKit.UIApplication
import enum CryptoKit.Insecure

public typealias DefaultDiskCache
    = DiskCache<FMDBInterface, FileManagerWrapper>

/// Cache objects onto the disk.
open class DiskCache<
    Database: DatabaseProtocol,
    FileStorage: FileStorageProtocol
>:
    Trimable,
    CodableObjectStoring,
    InitializableFromURL
{
    // MARK: - Public
    
    public var trimInfo = TrimInfo()
    
    public static var filesDirectoryName: String {
        FileStorage.filesDirectoryName
    }
    
    public static var trashDirectoryName: String {
        FileStorage.trashDirectoryName
    }
    
    public static var kilo: Int { 1024 }
    public typealias Database = Database
    
    /// URL of the parent directory of database and files.
    public let url: URL
    public let dataAccessQueue: DispatchQueue
    
    public lazy var preferredFilenameHashFunction: (String) -> String = md5String(of:)
    
    public let coder: Coding
    
    public func object<Object: Codable>(by key: Key) -> Object? {
        dataAccessQueue.sync {
            guard let data = performDataRetrieval(by: key) else { return nil }
            do {
                return try coder.decode(data)
            } catch {
                logDecodingFailure(from: #function, by: key, error: error)
                return nil
            }
        }
    }
    
    public func objects<Object: Codable>(by keys: [Key]) -> [Object?] {
        dataAccessQueue.sync {
            performDataRetrieval(by: keys)
                .enumerated()
                .map {
                    let key = keys[$0.offset]
                    guard let data = $0.element else { return nil }
                    do {
                        return try coder.decode(data)
                    } catch {
                        logDecodingFailure(from: #function, by: key, error: error)
                        return nil
                    }
                }
        }
    }
    
    public func nsObject<Object: NSCodable>(by key: Key) -> Object? {
        dataAccessQueue.sync {
            guard let data = self.performDataRetrieval(by: key) else { return nil }
            do {
                return try coder.nsDecode(data)
            } catch {
                logDecodingFailure(from: #function, by: key, error: error)
                return nil
            }
        }
    }
    
    public func nsObjects<Object: NSCodable>(by keys: [Key]) -> [Object?] {
        dataAccessQueue.sync {
            performDataRetrieval(by: keys)
                .enumerated()
                .map {
                    let key = keys[$0.offset]
                    guard let data = $0.element else { return nil }
                    do {
                        return try coder.nsDecode(data)
                    } catch {
                        logDecodingFailure(from: #function, by: key, error: error)
                        return nil
                    }
                }
        }
    }
    
    public func set<Object: Codable>(
        _ object: Object,
        by key: String
    ) throws {
        let encoded = try coder.encode(object)
        try dataAccessQueue.sync {
            try performInsertingData(encoded, by: key)
        }
    }
    
    public func set<Object: Codable>(_ keyValuePairs: [(Key, Object)]) throws {
        try dataAccessQueue.sync {
            try performInsertingObjects(keyValuePairs, using: coder.encode)
        }
    }
    
    public func nsSet<
        Object: NSCodable>(
        _ object: Object,
        by key: Key
    ) throws {
        let encoded = try coder.nsEncode(object)
        try dataAccessQueue.sync {
            try performInsertingData(encoded, by: key)
        }
    }
    
    public func nsSet<Object: NSCodable>(_ keyValuePairs: [(Key, Object)]) throws {
        try dataAccessQueue.sync {
            try performInsertingObjects(keyValuePairs, using: coder.nsEncode)
        }
    }
    
    public required convenience init(url: URL) throws {
        // These two initializers are actually ambiguous, so I had to add
        // the `qos` parameter to avoid an endlessly recursive call site.
        // But the user shouldn't have to worry, since whatever function
        // Swift resolves into would finally function the same.
        try self.init(url: url, qos: .utility)
    }
    
    public init(
        url: URL,
        qos: DispatchQoS = .utility,
        medium: Medium = .mixed(threshold: kilo),  // 1KB
        coder: Coding? = nil
    ) throws {
        self.url = url
        self.medium = medium
        self.coder = coder ?? Coder()
        self.dataAccessQueue = .init(
            label: .uniqueID(suffixedBy: "DiskCacheDataAccessQueue"),
            qos: qos
        )
        
        do {  // Create directories
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true)
        } catch {
            throw DiskCacheError.failedCreatingDirectory(error)
        }
        
        do {  // Create / connect database
            var database: Database!
            try dataAccessQueue.sync {
                database = try Database(url: url)
            }
            self.database = database
        } catch {
            throw DiskCacheError.databaseInitializationError(error)
        }
        
        do {  // Create FileStorage
            var fileStorage: FileStorage!
            try dataAccessQueue.sync {
                fileStorage = try .init(url: url)
            }
            self.fileStorage = fileStorage
        } catch {
            throw DiskCacheError.fileStorageInitializationError(error)
        }
        
        trim()
    }
    
    public func remove(_ key: String) throws {
        try dataAccessQueue.sync {
            try performDeletion(by: key)
        }
    }
    
    public func remove(_ keys: [String]) throws {
        guard !keys.isEmpty else { return }
        try dataAccessQueue.sync {
            try performDeletion(by: keys)
        }
    }
    
    public func removeAll() throws {
        try dataAccessQueue.sync {
            try database.removeAll()
            try fileStorage.deleteAll()
        }
    }
    
    public func contains(_ key: String) -> Bool {
        dataAccessQueue.sync {
            database.object(by: key) != nil
        }
    }
    
    public var count: Int {
        dataAccessQueue.sync {
            database.count
        }
    }
    
    public var size: Int {
        database.size
    }
    
    // MARK: - Internal
    var logger: Logging = defaultLogger
    
    var trimQueue: DispatchQueue {
        dataAccessQueue
    }
    
    /// The file manager that disk cache uses to create the directory.
    var fileManager: FileManager = .default
    
    func performTrim(with trimInfo: TrimInfo) {
        fileStorage.emptyTrash()
        try? remove(
            trimInfo.objectsToRemove(
                from: database.lessRecentlyAccessedObjects(limit: trimBatchSize),
                currentSize: size,
                availableCapacity: availableCapacity ?? .max)
            .map(\.key)
        )
    }
        
    // MARK: - Private
    private let medium: Medium
    private let database: Database
    private let fileStorage: FileStorage
}


private extension DiskCache {
    var trimBatchSize: Int {
        100
    }
    
    func md5String(of string: String) -> String {
        let data = string.data(using: .utf8)!
        return Insecure.MD5.hash(data: data)
            .reduce("") {
                $0 + String(format: "%02x", $1)
            }
    }
    
    var availableCapacity: Int? {
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let resourceValues = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            let capacityOptional = resourceValues.volumeAvailableCapacity
            guard
                let capacity = capacityOptional,
                capacity >= 0
            else {
                return nil
            }
            return Int(capacity)
        } catch {
            return nil
        }
    }
    
    func objectNeedToStoreAsFile(_ object: Database.Object) -> Bool {
        switch medium {
        case .file:
            return true
        case .mixed(let threshold):
            return (object.value?.count ?? 0) > threshold
        case .database:
            return false
        }
    }
    
    /// This method is NOT thread safe.
    func performInsertingData(_ data: Data, by key: String) throws {
        var databaseObject = Database.Object(key: key, value: data)
        databaseObject = try handleFileWriting(of: databaseObject)
        try database.insert(databaseObject)
    }
    
    /// ⚠️ NOT thread safe ⚠️ Inserting objects with key-value pairs and an encoding closure.
    func performInsertingObjects<Object>(
        _ keyValuePairs: [(Key, Object)],
        using encode: @escaping (Object) throws -> Data
    ) throws {
        let databaseObjects = try keyValuePairs
            .lazy
            .map { key, object in
                try Database.Object(key: key, value: encode(object))
            }
            .map {
                try handleFileWriting(of: $0)
            }
        try database.insert(databaseObjects)
    }
    
    /// ⚠️ NOT thread safe ⚠️ Retrieve the object's data on disk by key.
    func performDataRetrieval(by key: String) -> Data? {
        guard let databaseObject = database.object(by: key) else { return nil }
        return performDataRetrievalOfDatabaseObject(databaseObject)
    }
    
    /// ⚠️ NOT thread safe ⚠️ Retrieve the objects' data on disk by keys.
    func performDataRetrieval(by keys: [String]) -> [Data?] {
        database.objects(by: keys).map {
            guard let databaseObject = $0 else { return nil }
            return performDataRetrievalOfDatabaseObject(databaseObject)
        }
    }
    
    /// ⚠️ NOT thread safe ⚠️ Delete an object from disk by key.
    func performDeletion(by key: String) throws {
        switch medium {
        case .database: return
        case .file, .mixed:
            guard let databaseObject = database.object(by: key) else { return }
            if let filename = databaseObject.filename {
                try fileStorage.deleteFile(named: filename)
            }
            try database.remove(by: key)
        }
    }
    
    /// ⚠️ NOT thread safe ⚠️ Delete objects from disk by keys.
    func performDeletion(by keys: [String]) throws {
        switch medium {
        case .database:
            break
        case .file, .mixed:
            try fileStorage.deleteFiles(
                named: database.objects(by: keys)
                    .lazy
                    .compactMap {
                        $0?.filename
                    }
            )
        }
        try database.remove(by: keys)
    }
    
    /// ⚠️ NOT thread safe ⚠️ Retrieve data based on a database object.
    ///
    /// Data might be in the file system, or right in the object.
    /// This method is NOT thread safe.
    func performDataRetrievalOfDatabaseObject(_ databaseObject: Database.Object) -> Data? {
        if let filename = databaseObject.filename {
            guard let data = try? fileStorage.file(by: filename) else {
                return databaseObject.value
            }
            return data
        } else {
            return databaseObject.value
        }
    }
    
    /// ⚠️ NOT thread safe ⚠️ Write data into the file system if needed.
    ///
    /// If the data of an object is written into a file, the object removes its value.
    ///
    /// This method is NOT thread safe.
    func handleFileWriting(of databaseObject: Database.Object) throws -> Database.Object {
        guard objectNeedToStoreAsFile(databaseObject) else { return databaseObject }
        var databaseObject = databaseObject
        let filename = preferredFilenameHashFunction(databaseObject.key)
        databaseObject.filename = filename
        let data = databaseObject.value!
        databaseObject.value = .init()
        try fileStorage.write(data, named: filename)
        return databaseObject
    }
    
    func logDecodingFailure(from fn: String, by key: String, error: Error) {
        logger.logFault(
            "\(fn) Failed to decode one object keyed by \(key): \(error.localizedDescription)",
            on: .disk)
    }
}

extension DiskCache {
    /// Describes how the objects are stored on the disk.
    public enum Medium {
        /// All objects should be stored as files.
        ///
        /// The database is only a manifest of objects.
        case file
        /// All objects should be stored inside the database.
        ///
        /// The database contains all the objects. No file is generated.
        case database
        /// If an object is larger than a threshold, stored it as file, otherwise in the database.
        ///
        /// - Parameter threshold: If the size of an object is larger than this value, it gets stored as file.
        case mixed(threshold: Int)
    }
}


public enum DiskCacheError: Error {
    case databaseInitializationError(_ error: Error)
    case fileStorageInitializationError(_ error: Error)
    case failedCreatingDirectory(_ error: Error)
}
