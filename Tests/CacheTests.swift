//
//  CacheTests.swift
//  CacheTests
//
//  Created by iMoe Nya on 2020/11/24.
//

import XCTest
@testable import CacheKit

class CacheTests: XCTestCase {
    
    var cache: Cache!

    override func setUpWithError() throws {
        cache = try Cache(url: URLs.cache.appendingPathComponent(UUID().uuidString))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWriting() throws {
        let content = "content"
        do {  // write Swift `Codable` object:
            let key = "key1"
            try cache.set(content, by: key)
            XCTAssert(
                cache.contains(key)
            )
            let object: String? = cache.object(by: key)
            XCTAssert(
                object == content
            )
        }
        
        do {  // write `NSSecureCoding` `NSObject`:
            let key = "key2"
            try cache.nsSet(content as NSString, by: key)
            XCTAssert(
                cache.contains(key)
            )
            let object: NSString? = cache.nsObject(by: key)
            XCTAssert(
                object == (content as NSString)
            )
        }
    }
    
    func testBatchWriting() throws {
        let objectCount = 1000
        let contentPrefix = "content for "
        do {
            let keys = (0..<objectCount).map(String.init).map { "A" + $0 }
            let contents = keys.map { contentPrefix + $0 }
            try cache.set([(String, String)](zip(keys, contents)))
            
            (0..<objectCount).forEach {
                XCTAssert(cache.contains(keys[$0]))
                XCTAssert(cache.object(by: keys[$0]) == contents[$0])
            }
            
            let objects: [String?] = cache.objects(by: keys)
            XCTAssert(objects == contents)
        }
        
        do {
            let keys = (0..<objectCount).map(String.init).map { "B" + $0 }
            let contents = keys.map { contentPrefix + $0 }.map { $0 as NSString }
            try cache.nsSet([(String, NSString)](zip(keys, contents)))
            
            (0..<objectCount).forEach {
                XCTAssert(cache.contains(keys[$0]))
                XCTAssert(cache.nsObject(by: keys[$0]) == contents[$0])
            }
            
            let objects: [NSString?] = cache.nsObjects(by: keys)
            XCTAssert(objects == contents)
        }
    }
    
    func testRemoval() throws {
        let key = "key"
        let content = "content"
        try cache.set(content, by: key)
        
        XCTAssert(cache.contains(key))
        
        try cache.remove(key)
        XCTAssertFalse(cache.contains(key))
    }
    
    func testBatchRemoval() throws {
        let objectCount = 100
        let keys = (0..<objectCount).map(String.init)
        try cache.set(keys.map { ($0, "content") } )
        
        cache.objects(by: keys).forEach { (object: String?) -> Void in
            XCTAssertNotNil(object)
        }
        
        let objectCountToRemove = 20
        let keysToRemove = (0..<objectCountToRemove).map(String.init)
        try cache.remove(keysToRemove)
        
        cache.objects(by: keys).enumerated().forEach { (index: Int, object: String?) in
            if index < objectCountToRemove {
                XCTAssertNil(object)
            } else {
                XCTAssertNotNil(object)
            }
        }
        
        try cache.removeAll()
        
        cache.objects(by: keys).forEach { (object: String?) in
            XCTAssertNil(object)
        }
    }
}
