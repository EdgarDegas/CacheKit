//
//  DatabaseProtocolTests.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2020/12/28.
//

import XCTest
@testable import CacheKit
import FMDB

class DatabaseProtocolTests: XCTestCase {
    
    var fmdbInterface: FMDBInterface!
    var logger: TestLogger!
    var fmDatabase: TestFMDatabase!

    override func setUpWithError() throws {
        let url = URLs.cache.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true)
        fmdbInterface = try .init(url: url)
        logger = .init()
        fmdbInterface.logger = logger
        
        fmDatabase = .init(url: URLs.cache.appendingPathComponent(UUID().uuidString))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testRead() throws {
        addDummyData(to: fmdbInterface)
        do {
            let object = fmdbInterface.object(by: "0")
            XCTAssertNotNil(
                object
            )
            XCTAssert(
                String(data: object!.value!, encoding: .utf8) == "dummy"
            )
        }
        
        do {
            let object = fmdbInterface.object(by: "100")
            XCTAssertNotNil(
                object
            )
            XCTAssert(
                String(data: object!.value!, encoding: .utf8) == "dummy"
            )
        }
    }
    
    func testBatchRead() throws {
        addDummyData(to: fmdbInterface)
        let count = 100
        let objects = fmdbInterface.objects(by: (0..<count).map { String($0) })
        XCTAssert(objects.count == count)
        XCTAssert(String(data: objects[10]!.value!, encoding: .utf8) == "dummy")
    }
    
    func testWrite() throws {
        let key = "key"
        let oldValue = "old"
        let newValue = "new"
        
        do {
            var object = FMDBInterface.Object()
            object.key = key
            object.value = oldValue.data(using: .utf8)
            try fmdbInterface.insert(object)
        }
        
        do {
            let object = fmdbInterface.object(by: key)
            XCTAssert(object?.key == key)
            XCTAssert(object?.value == oldValue.data(using: .utf8))
        }
        
        do {
            var object = FMDBInterface.Object()
            object.key = key
            object.value = newValue.data(using: .utf8)
            try fmdbInterface.insert(object)
        }
        
        do {
            let object = fmdbInterface.object(by: key)
            XCTAssert(object?.key == key)
            XCTAssert(object?.value == newValue.data(using: .utf8))
        }
    }
    
    func testBatchWrite() throws {
        addDummyData(to: fmdbInterface)
    }
    
    func testCount() throws {
        let count = 80
        addDummyData(to: fmdbInterface, count: count)
        XCTAssert(fmdbInterface.count == count)
        
        let key = "0"  // an existing key
        let value = "different".data(using: .utf8)  // a different value
        
        do {
            var object = FMDBInterface.Object()
            object.key = key
            object.value = value
            try fmdbInterface.insert(object)
        }
        
        do {
            let object = fmdbInterface.object(by: key)
            XCTAssert(object?.value == value)
        }
        
        // Add an object with an exiting key won't addup
        XCTAssert(fmdbInterface.count == count)
    }
    
    func testSize() throws {
        XCTAssert(fmdbInterface.size == 0)
        
        let count = 120
        let sizePerObject = 1
        let size = count * sizePerObject
        addDummyData(to: fmdbInterface, count: count)
        XCTAssert(fmdbInterface.size == size)
        
        var object = FMDBInterface.Object()
        object.key = "0"  // an existing key
        object.size = 100
        try fmdbInterface.insert(object)
        XCTAssert(fmdbInterface.size == size - sizePerObject + 100)
        
        let error = NSError(domain: "size", code: 0, userInfo: nil)
        fmDatabase.errorToThrow = error
        fmdbInterface.database = fmDatabase
        
        XCTAssert(fmdbInterface.size == 0)
        XCTAssert(logger.logCount == 1)
        XCTAssert(  // the log message should ends with the error we gave
            logger.lastMessage!
                .reversed()
                .starts(
                    with: error.localizedDescription
                        .reversed()
                )
        )
    }
    
    func testDestroyAfterWriting() throws {
        var object = FMDBInterface.Object()
        object.key = "some key"
        try fmdbInterface.insert(object)
        try fmdbInterface.removeAll()
    }

    func testSQLComposer() {
        let composer = SQLComposer()
        let tableName = "my-table"
        
        let creationSucceeded: Bool = {
            let creationSQL = "pragma journal_mode = wal; pragma synchronous = normal; create table if not exists \(tableName) (key text primary key not null, value blob, accessTime integer); create index if not exists accessTime_idx on \(tableName)(accessTime);"
            let actualSQL = composer.createTable(
                    named: tableName,
                    withColumns: [
                        .init(name: "key", type: "text", primary: true, nullable: false),
                        .init(name: "value", type: "blob"),
                        .init(name: "accessTime", type: "integer", indexed: true)
                    ]
            )
            return actualSQL == creationSQL
        }()
        XCTAssert(creationSucceeded)
        
        let insertionSucceeded: Bool = {
            let insertionSQL = "insert or replace into \(tableName) (one, two, three) values (?, ?, ?);"
            let actualSQL = composer.insert(
                into: tableName,
                columns: ["one", "two", "three"]
            )
            return insertionSQL == actualSQL
        }()
        XCTAssert(insertionSucceeded)
        
        let selectionSucceeded: Bool = {
            let selectionSQL = "select * from \(tableName) where key = ?;"
            let actualSQL = composer.select(from: tableName, by: "key", amount: 1)
            return selectionSQL == actualSQL
        }()
        XCTAssert(selectionSucceeded)
        
        let multipleSelectionSucceeded: Bool = {
            let selectionSQL = "select * from \(tableName) where key in (?, ?, ?);"
            let actualSQL = composer.select(from: tableName, by: "key", amount: 3)
            return selectionSQL == actualSQL
        }()
        XCTAssert(multipleSelectionSucceeded)
        
        let orderedSelectionSucceeded: Bool = {
            let selectionSQL = "select * from \(tableName) order by age asc limit 100;"
            let actualSQL = composer.selectRecords(
                from: tableName,
                orderedBy: "age",
                ascending: true,
                limitedAt: 100)
            return selectionSQL == actualSQL
        }()
        XCTAssert(orderedSelectionSucceeded)
        
        XCTAssert(
            composer.selectCount(from: tableName) == "select count(*) from \(tableName);"
        )
        XCTAssert(
            composer.selectSum(from: tableName, of: "cost") == "select sum(cost) from \(tableName);"
        )
        
        XCTAssert(
            composer.update(
                from: tableName,
                set: ["k1", "k2"],
                by: "key",
                amount: 5
            )
            ==
            "update \(tableName) set k1 = ?, k2 = ? where key in (?, ?, ?, ?, ?);"
        )
        
        XCTAssert(
            composer.update(from: tableName, set: ["k1", "k3"], by: "key", amount: 1)
            ==
            "update \(tableName) set k1 = ?, k3 = ? where key = ?;"
        )
        
        let deletionSucceeded: Bool = {
            let deletionSQL = "delete from \(tableName) where key = ?;"
            let actualSQL = composer.delete(from: tableName, by: "key", amount: 1)
            return deletionSQL == actualSQL
        }()
        XCTAssert(deletionSucceeded)
        
        let multipleDeletionSucceeded: Bool = {
            let deletionSQL = "delete from \(tableName) where key in (?, ?);"
            let actualSQL = composer.delete(from: tableName, by: "key", amount: 2)
            return deletionSQL == actualSQL
        }()
        XCTAssert(multipleDeletionSucceeded)
    }
}

private extension DatabaseProtocolTests {
    func addDummyData(to fmdbInterface: FMDBInterface, count: Int = 1000) {
        try! fmdbInterface.insert (
            (0..<count).map {
                var object = FMDBInterface.Object()
                object.key = String($0)
                object.value = "dummy".data(using: .utf8)
                object.size = 1
                return object
            }
        )
    }
}
