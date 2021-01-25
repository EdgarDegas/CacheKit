//
//  DiskCacheTests.swift
//  CacheTests
//
//  Created by iMoe Nya on 2020/11/27.
//

import XCTest
@testable import CacheKit

class DiskCacheTests: XCTestCase {
    
    typealias DiskCache = CacheKit.DefaultDiskCache

    // Disk cache is mixed by default, as long as you insert an object larger
    // than its threshold, which by default is 1KB:
    var diskCache: DiskCache!
    var url: URL!
    var testLogger: TestLogger!

    override func setUpWithError() throws {
        url = URLs.cache.appendingPathComponent(UUID().uuidString)
        diskCache = try! DiskCache(url: url)
        testLogger = TestLogger()
        diskCache.logger = testLogger
    }
    
    func testWriteDatabase() throws {
        let diskCache = try! DiskCache(url: url, medium: .database)
        let key = "key"
        let content = "random content"
        
        do {  // test Swift `Codable` object
            try diskCache.set(content, by: key)
            
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            // test `object(by:)`:
            let object: String? = diskCache.object(by: key)
            XCTAssert(
                object == content
            )
            
            // test size:
            let size = encode(object).count
            XCTAssert(diskCache.size == size)
        }
        
        do {  // test `NSSecureCoding` `NSObject`
            try diskCache.nsSet(content as NSString, by: key)
            
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            // test `object(by:)`:
            let object: NSString? = diskCache.nsObject(by: key)
            XCTAssert(
                object == content as NSString
            )
            
            // test size:
            let size = archive(object!).count
            XCTAssert(size == diskCache.size)
        }
    }
    
    func testWriteFile() throws {
        let diskCache = try! DiskCache(url: url, medium: .file)
        let key = "key"
        let content = "random content"
        let filename = diskCache.preferredFilenameHashFunction(key)
        
        do {  // test Swift `Codable` object
            try diskCache.set(content, by: key)
            
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            XCTAssert(  // look for file in the filesystem:
                try!
                    String(
                        data: Data(
                            contentsOf: url
                                .appendingPathComponent(DiskCache.filesDirectoryName)
                                .appendingPathComponent(filename)
                        ), encoding: .utf8
                    )
                    ==
                    "\"\(content)\""
            )
        
            // test `object(by:)`:
            let object: String? = diskCache.object(by: key)
            XCTAssert(
                object == content
            )
            
            // test size:
            let size = encode(object).count
            XCTAssert(diskCache.size == size)
        }
        
        do {  // test `NSSecureCoding` `NSObject`
            try diskCache.nsSet(content as NSString, by: key)
            
            XCTAssert(
                diskCache.contains(key)
            )
            
            XCTAssert(  // look for file in the filesystem:
                try!
                    NSKeyedUnarchiver.unarchivedObject(
                        ofClass: NSString.self,
                        from: Data(
                            contentsOf: url
                                .appendingPathComponent(DiskCache.filesDirectoryName)
                                .appendingPathComponent(filename)
                        )
                    )
                    ==
                    content as NSString
            )
        
            // test `object(by:)`:
            let object: NSString? = diskCache.nsObject(by: key)
            XCTAssert(
                object == content as NSString
            )
            
            // test size:
            let size = archive(object!).count
            XCTAssert(size == diskCache.size)
        }
    }
    
    func testWriteSmallObjectIntoMixed() throws {
        let key = "key"
        let content = "short content"
        try diskCache.set(content, by: key)
        let filename = diskCache.preferredFilenameHashFunction(key)
        
        do {  // test Swift `Codable` objects:
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            XCTAssertFalse(  // content is too short to be stored as file
                FileManager.default.fileExists(
                    atPath: url
                        .appendingPathComponent(DiskCache.filesDirectoryName)
                        .appendingPathComponent(filename)
                        .path
                )
            )
            
            // test `object(by:)`:
            let object: String? = diskCache.object(by: key)
            XCTAssert(
                object == content
            )
            
            // test size:
            let size = encode(object).count
            XCTAssert(diskCache.size == size)
        }
        
        do {  // test `NSSecureCoding` `NSObject`s:
            try diskCache.nsSet(content as NSString, by: key)
            
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            XCTAssertFalse(  // content is too short to be stored as file
                FileManager.default.fileExists(
                    atPath: url
                        .appendingPathComponent(DiskCache.filesDirectoryName)
                        .appendingPathComponent(filename)
                        .path
                )
            )
            
            // test `object(by:)`:
            let object: NSString? = diskCache.nsObject(by: key)
            XCTAssert(
                object == content as NSString
            )
            
            // test size:
            let size = archive(object!).count
            XCTAssert(size == diskCache.size)
        }
    }
    
    func testWriteMixed() throws {
        let key = "key"
        let content = String(repeating: "A", count: 1024*1024)
        try diskCache.set(content, by: key)
        let filename = diskCache.preferredFilenameHashFunction(key)
        
        do {  // test Swift `Codable` objects:
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            XCTAssert(  // look for file in the filesystem:
                try!
                    String(
                        data: Data(
                            contentsOf: url
                                .appendingPathComponent(DiskCache.filesDirectoryName)
                                .appendingPathComponent(filename)
                        ), encoding: .utf8
                    )
                    ==
                    "\"\(content)\""
            )
            
            // test `object(by:)`:
            let object: String? = diskCache.object(by: key)
            XCTAssert(
                object == content
            )
            
            // test size:
            let size = encode(object).count
            XCTAssert(diskCache.size == size)
        }
        
        do {  // test `NSSecureCoding` `NSObject`s:
            try diskCache.nsSet(content as NSString, by: key)
            
            XCTAssert(  // test `contains`:
                diskCache.contains(key)
            )
            
            XCTAssert(  // look for file in the filesystem:
                try!
                    Data(
                        contentsOf: url
                            .appendingPathComponent(DiskCache.filesDirectoryName)
                            .appendingPathComponent(filename)
                    )
                    ==
                    archive(content as NSString)
            )
            
            // test `object(by:)`:
            let object: NSString? = diskCache.nsObject(by: key)
            XCTAssert(
                object == content as NSString
            )
            
            // test size:
            let size = archive(object!).count
            XCTAssert(size == diskCache.size)
        }
    }
    
    func testBatchWriting() throws {
        let count = 100
        let valueOffset = 100
        let keys = (0..<count).map(String.init)
        let values = (valueOffset..<valueOffset+count).map(String.init)
        
        do {  // test Swift `Codable` objects:
            let objectsAndKeys = [(String, String)](zip(keys, values))
            try diskCache.set(objectsAndKeys)
            
            // test count:
            XCTAssert(diskCache.count == count)
            
            // test object(by:)
            objectsAndKeys.forEach {
                let object: String? = diskCache.object(by: $0.0)
                XCTAssert(object == $0.1)
            }
            
            // test objects(by:)
            let objects: [String?] = diskCache.objects(by: keys)
            objects.enumerated().forEach {
                XCTAssert($0.element == values[$0.offset])
            }
            
            // test size:
            let encodedValues = values.map(encode)
            let size = encodedValues.reduce(0) { $0 + $1.count }
            XCTAssert(Int(size) == diskCache.size)
        }
        
        do {  // test `NSSecureCoding` `NSObject`s:
            let keyValuePairs = [(String, NSString)](zip(keys, values.map(NSString.init)))
            try diskCache.nsSet(keyValuePairs)
            
            // test count:
            XCTAssert(diskCache.count == count)
            
            // test object(by:)
            keyValuePairs.forEach {
                let object: NSString? = diskCache.nsObject(by: $0.0)
                XCTAssert(object == $0.1)
            }
            
            // test objects(by:)
            let objects: [NSString?] = diskCache.nsObjects(by: keys)
            objects.enumerated().forEach {
                XCTAssert($0.element == values[$0.offset] as NSString)
            }
            
            // test size:
            let encodedValues = values.lazy.map(NSString.init).map(archive)
            let size = encodedValues.reduce(0) { $0 + $1.count }
            XCTAssert(Int(size) == diskCache.size)
        }
    }
    
    func testMissing() throws {
        let key = "non-existing key"
        XCTAssertFalse(diskCache.contains(key))
        do {
            let object: String? = diskCache.object(by: key)
            XCTAssertNil(object)
            // No log needed for non-existing key:
            XCTAssert(testLogger.logCount == 0)
        }
        
        do {
            let object: NSString? = diskCache.nsObject(by: key)
            XCTAssertNil(object)
            // No log needed for non-existing key:
            XCTAssert(testLogger.logCount == 0)
        }
        
        do {
            let objects: [String?] = diskCache.objects(by: [key])
            XCTAssert(objects.first == Optional<String>.none)
            // No log needed for non-existing key:
            XCTAssert(testLogger.logCount == 0)
        }
        
        do {
            let objects: [NSString?] = diskCache.nsObjects(by: [key])
            XCTAssert(objects.first == Optional<NSString>.none)
            // No log needed for non-existing key:
            XCTAssert(testLogger.logCount == 0)
        }
    }
    
    /// Set, e.g. an Integer object, into the disk cache, and try to retrieve a String object by
    /// the same key.
    ///
    /// All the retrieval methods should return nil. Under the bonnet, there actually is some data
    /// corresponding to that key, but the disk cache should have problem decoding that data
    /// into a wrong type. So the logger of the disk cache should have logged this fault.
    func testGettingObjectWhileAssumingAWrongType() throws {
        let key = "key"
        let content = 1
        try diskCache.set(content, by: key)
        
        // yes, there is such object:
        XCTAssert(diskCache.contains(key))
        
        // but can we retrieve it as a String / NSString?
        do {
            // reset log count:
            testLogger.logCount = 0
            let stringContent: String? = diskCache.object(by: key)
            XCTAssertNil(stringContent)
            // a log should be sent:
            XCTAssert(testLogger.logCount == 1)
        }
        
        do {
            // reset log count:
            testLogger.logCount = 0
            let stringContent: NSString? = diskCache.nsObject(by: key)
            XCTAssertNil(stringContent)
            // a log should be sent:
            XCTAssert(testLogger.logCount == 1)
        }
        
        do {
            // reset log count:
            testLogger.logCount = 0
            let stringContents: [String?] = diskCache.objects(by: [key])
            XCTAssert(stringContents.first == Optional<String>.none)
            // a log should be sent:
            XCTAssert(testLogger.logCount == 1)
        }
        
        do {
            // reset log count:
            testLogger.logCount = 0
            let stringContents: [NSString?] = diskCache.nsObjects(by: [key])
            XCTAssert(stringContents.first == Optional<NSString>.none)
            // a log should be sent:
            XCTAssert(testLogger.logCount == 1)
        }
    }
    
    func testRemoval() throws {
        let key = "key"
        let content = "random content"
        let diskCache = try! DiskCache(url: url, medium: .file)
        try diskCache.set(content, by: key)
        let filename = diskCache.preferredFilenameHashFunction(key)
        
        // validate existence:
        XCTAssert(
            diskCache.contains(key)
        )
        XCTAssert(
            FileManager.default.fileExists(
                atPath: url
                    .appendingPathComponent(DiskCache.filesDirectoryName)
                    .appendingPathComponent(filename)
                    .path
            )
        )
        
        // test remove:
        try diskCache.remove(key)
        XCTAssertFalse(
            diskCache.contains(key)
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: url
                    .appendingPathComponent(DiskCache.filesDirectoryName)
                    .appendingPathComponent(filename)
                    .path
            )
        )
    }
    
    func testRemovingMultipleObjects() throws {
        // insert some dummy objects:
        let objectCount = 1000
        let keys: [String] = (0..<objectCount).map(String.init)
        let keyValuePairs: [(String, String)] = keys.map {
            ($0, "content by \($0)")
        }
        try diskCache.set(keyValuePairs)
        
        // make sure that insertion succeeded
        XCTAssert(diskCache.count == objectCount)
        
        keys.forEach {
            XCTAssert(diskCache.contains($0))
        }
        
        // remove some objects:
        let objectsToRemoveCount = 100
        let keysToRemove = (0..<objectsToRemoveCount).map(String.init)
        let keysNotRemoved = (objectsToRemoveCount..<objectCount).map(String.init)
        try diskCache.remove(keysToRemove)
        
        keysToRemove.forEach {
            XCTAssertFalse(
                diskCache.contains($0)
            )
        }
        
        keysNotRemoved.forEach {
            XCTAssert(
                diskCache.contains($0)
            )
        }
    }
    
    func testRemovingAll() throws {
        let key = "key"
        let content = "random content"
        
        XCTAssertFalse(  // no such object
            diskCache.contains(key)
        )
        
        try diskCache.set(content, by: key)
        
        XCTAssert(  // then there is such object
            diskCache.contains(key)
        )
        
        try diskCache.removeAll()
        
        XCTAssertFalse(  // object deleted
            diskCache.contains(key)
        )
    }
    
    func testCountTriming() {
        var trimInfo = DiskCache.TrimInfo()
        
        // 10 objects:
        let objectCount = 10
        let dummyObjects = (0..<objectCount).map { key -> DiskCache.Database.Object in
            var object = DiskCache.Database.Object()
            object.key = "\(key)"
            return object
        }
        
        XCTAssert(  // should return no object because there's no limit:
            trimInfo.objectsToRemove(
                from: dummyObjects,
                currentSize: Int(objectCount),
                availableCapacity: .max
            )
            .isEmpty
        )
        
        // disk cache should limit the number of objects at 2:
        trimInfo.countLimit = 2
        
        // trim info should return the first 8 objects:
        let toRemove = trimInfo.objectsToRemove(
            from: dummyObjects,
            currentSize: 0,
            availableCapacity: .max)
        XCTAssert(toRemove.count == 8)
        XCTAssert(toRemove.first?.key == "0")
        XCTAssert(toRemove.last?.key == "7")
    }
    
    func testSizeTriming() {
        var trimInfo = DiskCache.TrimInfo()
        
        // 10 objects, 1 byte each:
        let objectCount = 10
        let sizePerObject: Int = 1
        
        let dummyObjects = (0..<objectCount).map { key -> DiskCache.Database.Object in
            var object = DiskCache.Database.Object()
            object.key = "\(key)"
            object.size = sizePerObject
            return object
        }
        
        XCTAssert(  // should return no object because there's no limit:
            trimInfo.objectsToRemove(
                from: dummyObjects,
                currentSize: Int(objectCount) * sizePerObject,
                availableCapacity: .max
            )
            .isEmpty
        )
        
        // disk cache should limit at most bytes:
        trimInfo.sizeLimit = 2
        
        // trim info should return the first 8 objects:
        let toRemove = trimInfo.objectsToRemove(
            from: dummyObjects,
            currentSize: Int(objectCount),
            availableCapacity: .max)
        XCTAssert(toRemove.count == 8)
        XCTAssert(toRemove.first?.key == "0")
        XCTAssert(toRemove.last?.key == "7")
    }
    
    func testAgeTriming() {
        var trimInfo = DiskCache.TrimInfo()
    
        // 10 objects:
        let objectCount = 10
        let dummyObjects =
            // 8 objects are created 2 seconds earlier:
            (0..<objectCount-2).map { key -> DiskCache.Database.Object in
                var object = DiskCache.Database.Object()
                object.key = "\(key)"
                object.accessTime = Int(CACurrentMediaTime()) - 2
                return object
            }
            // 2 objects are created just now:
            + (objectCount-2..<objectCount).map { key -> DiskCache.Database.Object in
                var object = DiskCache.Database.Object()
                object.key = "\(key)"
                return object
            }
        
        XCTAssert(  // should return no object when no limit is specified:
            trimInfo.objectsToRemove(
                from: dummyObjects,
                currentSize: Int(objectCount),
                availableCapacity: .max
            )
            .isEmpty
        )
        
        // disk cache should remove all items older than 1 second:
        trimInfo.ageLimit = 1
        
        // trim info should return the first 8 objects:
        let toRemove = trimInfo.objectsToRemove(
            from: dummyObjects,
            currentSize: Int(objectCount),
            availableCapacity: .max)
        
        XCTAssert(toRemove.count == 8)
        XCTAssert(toRemove.first?.key == "0")
        XCTAssert(toRemove.last?.key == "7")
    }
    
    func testFreeDiskSpaceTriming() {
        var trimInfo = DiskCache.TrimInfo()
        
        // suppose there are 12 bytes free space:
        let availableSpace: Int = 12
        
        // 10 objects, 1 bytes each, 10 bytes in total:
        let objectCount = 10
        let sizePerObject: Int = 1
        let currentSize = Int(objectCount) * sizePerObject
        let dummyObjects = (0..<objectCount).map { key -> DiskCache.Database.Object in
            var object = DiskCache.Database.Object()
            object.key = "\(key)"
            object.size = sizePerObject
            return object
        }
        
        XCTAssert(  // should return no object by default:
            trimInfo.objectsToRemove(
                from: dummyObjects,
                currentSize: currentSize,
                availableCapacity: availableSpace
            )
            .isEmpty
        )
        
        // diskCache guarantees 5 bytes of free space on the user's device:
        trimInfo.freeDiskSpace = 5
        
        // trim info should return the first 3 objects (3 = 5 - (12 - 10)):
        let toRemove = trimInfo.objectsToRemove(
            from: dummyObjects,
            currentSize: currentSize,
            availableCapacity: availableSpace
        )
        
        XCTAssert(toRemove.count == 3)
        XCTAssert(toRemove.first?.key == "0")
        XCTAssert(toRemove.last?.key == "2")
    }
    
    func testErrorInitializingDatabase() throws {
        let errorDomain = "Database internal error"
        let error = NSError(domain: errorDomain, code: 1, userInfo: nil)
        errorToThrowInitializingDatabase = error
        XCTAssertThrowsError(
            _ = try CacheKit.DiskCache<
                TestDatabase, FileManagerWrapper
            >(
                url: URLs.cache.appendingPathComponent(UUID().uuidString)
            )
        ) {
            if case DiskCacheError.databaseInitializationError(DatabaseError.initializationFailed(let internalError)) = $0 {
                XCTAssertNotNil(internalError)
                XCTAssert(
                    (internalError! as NSError).domain == errorDomain
                )
            } else {
                XCTAssert(false)
            }
        }
    }
    
    func testErrorInitializingFileStorage() throws {
        let errorDomain = "File storage internal error"
        errorToThrowInitializingFileStorage = NSError(domain: errorDomain, code: 0, userInfo: nil)
        XCTAssertThrowsError(
            _ = try CacheKit.DiskCache<
                FMDBInterface, TestFileManagerWrapper
            >(
                url: URLs.cache.appendingPathComponent(UUID().uuidString)
            )
        ) {
            if case DiskCacheError.fileStorageInitializationError(FileStorageError.failedCreatingDirectory(let internalError)) = $0 {
                XCTAssert(
                    (internalError as NSError).domain == errorDomain
                )
            } else {
                XCTAssert(false)
            }
        }
    }
}

private var errorToThrowInitializingDatabase: Error?
private var errorToThrowInitializingFileStorage: Error?

private extension DiskCacheTests {
    final class TestFileManagerWrapper: FileManagerWrapper, Throwable {
        var errorToThrow: Error? {
            guard let error = errorToThrowInitializingFileStorage else { return nil }
            return FileStorageError.failedCreatingDirectory(error)
        }
        
        var numberOfSuccessBeforeThrowingError: Int = 0
        
        var successCount: Int = 0
        
        func incrementSuccessCount() {
            successCount += 1
        }
        
        required init(url: URL) throws {
            try super.init(url: url)
            _ = try tryThrow {
                ""
            }
        }
    }
    
    final class TestDatabase: FMDBInterface, Throwable {
        func incrementSuccessCount() {
            successCount += 1
        }
        
        var errorToThrow: Error? {
            guard let error = errorToThrowInitializingDatabase else { return nil }
            return DatabaseError.initializationFailed(error)
        }
        
        var numberOfSuccessBeforeThrowingError: Int = 0
        var successCount: Int = 0
        
        override init(url: URL, sqlComposer: SQLComposing? = nil) throws {
            try super.init(url: url, sqlComposer: sqlComposer)
            _ = try tryThrow {
                ""
            }
        }
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    func encode<Object: Codable>(_ object: Object) -> Data {
        try! Self.encoder.encode(object)
    }
    
    func decoder<Object: Codable>(_ data: Data, into type: Object.Type) -> Object {
        try! Self.decoder.decode(type, from: data)
    }
    
    func archive(_ object: NSCodable) -> Data {
        try! NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
    }
    
    func unarchive<Object: NSCodable>(_ data: Data) -> Object {
        try! NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)!
    }
}
