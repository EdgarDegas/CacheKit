//
//  FMDBInterface.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/28.
//

import FMDB

/// A wrapper of FMDB, which is a wrapper of SQLite.
///
/// Check `DatabaseProtocol` for docs of the public functions.
open class FMDBInterface: DatabaseProtocol {
    public typealias Object = SQLiteObject
    public typealias LessAccessedObjects = [Object]
    
    /// Number of objects stored.
    ///
    /// This figure is calculated everytime you ask for it.
    public var count: Int {
        let sql = sqlComposer.selectCount(from: tableName)
        guard
            let result = (try? database.executeQuery(sql, values: nil)),
            result.next() == true
        else {
            return 0
        }
        return Int(result.longLongInt(forColumnIndex: 0))
    }

    /// The overall size of all the objects.
    ///
    /// This figure is calculated everytime you ask for it.
    public var size: Int {
        let sql = sqlComposer.selectSum(from: tableName, of: Key.size.rawValue)
        guard
            let result = (try? database.executeQuery(sql, values: nil)),
            result.next() == true
        else {
            logQueryFault(from: #function, error: database.lastError())
            return 0
        }
        return Int(result.longLongInt(forColumnIndex: 0))
    }
    
    public let databaseURL: URL
    
    public func lessRecentlyAccessedObjects(limit: Int) -> [Object] {
        let sql = sqlComposer.selectRecords(
            from: tableName,
            orderedBy: Key.accessTime.rawValue,
            ascending: true,
            limitedAt: limit)
        guard let result = (try? database.executeQuery(sql, values: nil)) else {
            logQueryFault(from: #function, error: database.lastError())
            return [ ]
        }
        return .init(fmResult: result)
    }

    public func insert(_ object: Object) throws {
        let values = valuesOfObject(object, in: keys)
        let sql = sqlComposer.insert(into: tableName, columns: keysInString)
        do {
            try database.executeUpdate(sql, values: values)
        } catch {
            throw DatabaseError.insertionFailed(error)
        }
    }
    
    public func insert(_ objects: [SQLiteObject]) throws {
        let began = database.beginDeferredTransaction()
        try objects.forEach {
            try insert($0)
        }
        if began {
            let written = database.commit()
            guard written else {
                throw DatabaseError.insertionFailed(database.lastError())
            }
        }
    }
    
    public func object(by key: String) -> Object? {
        let sql = sqlComposer.select(
            from: tableName,
            by: Key.key.rawValue,
            amount: 1)
        guard
            let result = (try? database.executeQuery(sql, values: [key]))
        else {  // log fault if the query throwed an error:
            logQueryFault(from: #function, error: database.lastError())
            return nil
        }
        
        guard result.next() == true else {
            return nil
        }
        updateAccessTime(by: key)
        return Object(fmResult: result)
    }
    
    public func objects(by keys: [String]) -> [Object?] {
        guard !keys.isEmpty else { return [ ] }
        let sql = sqlComposer.select(
            from: tableName,
            by: Key.key.rawValue,
            amount: keys.count
        )
        guard let result = (try? database.executeQuery(sql, values: keys)) else {
            logQueryFault(from: #function, error: database.lastError())
            return [ ]
        }
        
        var keysAndIndex = [String: Int]()
        keys.enumerated().forEach {
            keysAndIndex[$0.element] = $0.offset
        }
        var keysToUpdateAccessTime = [String]()
        var toReturn = [Object?](repeating: nil, count: keys.count)
        while result.next() {
            guard let object = Object(fmResult: result) else {
                continue
            }
            keysToUpdateAccessTime.append(object.key)
            guard let index = keysAndIndex[object.key] else { continue }
            toReturn[index] = object
        }
        
        updateAccessTime(by: keysToUpdateAccessTime)
        return toReturn
    }
    
    public func remove(by key: String) throws {
        let sql = sqlComposer.delete(from: tableName, by: Key.key.rawValue, amount: 1)
        do {
            try database.executeUpdate(sql, values: [key])
        } catch {
            throw DatabaseError.deletionFailed(error)
        }
    }

    public func remove(by keys: [String]) throws {
        guard !keys.isEmpty else { return }
        guard keys.count > 1 else {
            try remove(by: keys.first!)
            return
        }
        let sql = sqlComposer.delete(
            from: tableName,
            by: Key.key.rawValue,
            amount: keys.count
        )
        do {
            try database.executeUpdate(sql, values: keys)
        } catch {
            throw DatabaseError.deletionFailed(error)
        }
    }

    public func removeAll() throws {
        try destroyDatabase()
        try initializeDatabase()
    }

    public convenience required init(url: URL) throws {
        try self.init(url: url, sqlComposer: nil)
    }
    
    /// Initialize an FMDB interface.
    ///
    /// - Parameter url: URL of the parent directory of the database files.
    /// - Parameter sqlComposer: Build SQL statements for the `FMDBInterface`.
    ///             Nil to use the default one.
    public init(url: URL, sqlComposer: SQLComposing? = nil) throws {
        tableName = "manifest"
        self.sqlComposer = sqlComposer ?? SQLComposer()
        databaseURL = url
            .appendingPathComponent(tableName)
            .appendingPathExtension(databaseFileExtension)
        try initializeDatabase()
    }
    
    // MARK: - internal
    var logger: Logging = defaultLogger
    var database: FMDatabase!

    // MARK: - private
    private let tableName: String
    private var databaseFileExtension = "sqlite"
    private let sqlComposer: SQLComposing
}

private extension FMDBInterface {
    /// Destroy the FMDB instance and remove all the database file on the filesystem.
    ///
    /// Never call this method in any thread except the thread you used to
    /// access the database.
    func destroyDatabase() throws {
        database = nil
        try FileManager.default.removeItem(at: databaseURL)
        func deleteFileWithExtension(_ `extension`: String) {
            do {
                try FileManager.default.removeItem(
                    at: databaseURL
                        .deletingLastPathComponent()
                        .appendingPathComponent(tableName)
                        .appendingPathExtension("\(databaseFileExtension)-\(`extension`)")
                )
            } catch {
                logger.logFault(
                    "\(#function): failed to delete \(tableName).\(databaseFileExtension)-\(`extension`): \(error.localizedDescription)",
                    on: .disk)
            }
        }
        
        deleteFileWithExtension("shm")
        deleteFileWithExtension("wal")
    }
    
    /// Create an FMDB instance.
    ///
    /// Never call this method in any thread except the thread you used to
    /// access the database.
    func initializeDatabase() throws {
        database = .init(url: databaseURL)
        database.shouldCacheStatements = true

        let opened = database.open()
        guard opened else {
            throw DatabaseError.initializationFailed(database.lastError())
        }
        let created = database.executeStatements(tableCreationSQL)
        guard created else {
            throw DatabaseError.initializationFailed(database.lastError())
        }
    }
    
    typealias Key = DatabaseObjectVitalKey
    
    var keys: [Key] {
        [.key, .value, .size, .accessTime, .filename]
    }

    var keysInString: [String] {
        keys.map(\.rawValue)
    }

    var tableCreationSQL: String {
        let textType = "text"
        let dataType = "blob"
        let integerType = "integer"
        return sqlComposer.createTable(
            named: tableName,
            withColumns: [
                .init(
                    name: Key.key.rawValue,
                    type: textType,
                    primary: true,
                    nullable: false
                ),
                .init(
                    name: Key.value.rawValue,
                    type: dataType
                ),
                .init(
                    name: Key.size.rawValue,
                    type: integerType,
                    nullable: false
                ),
                .init(
                    name: Key.accessTime.rawValue,
                    type: integerType,
                    nullable: false,
                    indexed: true
                ),
                .init(
                    name: Key.filename.rawValue,
                    type: textType
                )
            ])
    }
    
    func valuesOfObject(_ object: Object, in sequence: [DatabaseObjectVitalKey]) -> [Any] {
        sequence.map {
            switch $0 {
            case .key:
                return object.key
            case .value:
                return object.value as Any
            case .size:
                return object.size
            case .accessTime:
                return object.accessTime
            case .filename:
                return object.filename as Any
            }
        }
    }
    
    func updateAccessTime(by key: String) {
        let sql = sqlComposer.update(
            from: tableName,
            set: [Key.accessTime.rawValue],
            by: Key.key.rawValue,
            amount: 1
        )
        try? database.executeUpdate(sql, values: [Int.now, key])
    }
    
    func updateAccessTime(by keys: [String]) {
        guard !keys.isEmpty else { return }
        guard keys.count > 1 else {
            updateAccessTime(by: keys.first!)
            return
        }
        let sql = sqlComposer.update(
            from: tableName,
            set: [Key.accessTime.rawValue],
            by: Key.key.rawValue,
            amount: keys.count
        )
        try? database.executeUpdate(sql, values: [Int.now] + keys)
    }
    
    func logQueryFault(from fn: String, error: Error) {
        logger.logFault(
            "Failed to query \(fn) from \(tableName): \(error.localizedDescription)",
            on: .disk)
    }
}

private extension DatabaseObjectProtocol {
    init?(fmResult: FMResultSet) {
        guard let key = fmResult.string(forColumn: Key.key.rawValue) else {
            return nil
        }
        self.init()
        self.key = key
        self.value = fmResult.data(forColumn: Key.value.rawValue)
        size = Int(fmResult.longLongInt(forColumn: Key.size.rawValue))
        filename = fmResult.string(forColumn: Key.filename.rawValue)
        accessTime = Int(fmResult.longLongInt(forColumn: Key.accessTime.rawValue))
    }
}

private extension Array where Element: DatabaseObjectProtocol {
    init(fmResult: FMResultSet) {
        self.init()
        while fmResult.next() {
            guard let object = Element(fmResult: fmResult) else { continue }
            append(object)
        }
    }
}
