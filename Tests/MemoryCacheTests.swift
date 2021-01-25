//
//  MemoryCacheTests.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2021/1/20.
//

import XCTest
import class UIKit.UIApplication
@testable import CacheKit

class MemoryCacheTests: XCTestCase {
    
    var memoryCache: MemoryCache!

    override func setUpWithError() throws {
        memoryCache = MemoryCache(name: UUID().uuidString)
    }
    
    func testWriteAndRemoval() throws {
        let key = "key"
        let object = 1

        // insert the object
        memoryCache.set(object, by: key)
        XCTAssert(memoryCache.count == 1)
        XCTAssert(memoryCache.contains(key))
        XCTAssert(
            memoryCache.object(by: key) == object
        )
        XCTAssert(
            memoryCache.size == 8  // on 64-bit platform
        )
        
        // replace the existing object with another object
        let anotherObject = 2
        // insert with the batch method
        memoryCache.set([(key, anotherObject)])
        XCTAssert(memoryCache.count == 1)
        XCTAssert(memoryCache.contains(key))
        XCTAssert(
            memoryCache.object(by: key) == anotherObject
        )
        XCTAssert(
            memoryCache.size == 8
        )
        
        memoryCache.remove(key)
        XCTAssert(memoryCache.count == 0)
        XCTAssertFalse(memoryCache.contains(key))
        XCTAssert(memoryCache.size == 0)
        
        // should be OK remove non-existing key:
        memoryCache.remove("non-existing key")
    }
    
    func testBatchWriteAndRemoval() throws {
        // memory cache has no object now
        XCTAssert(memoryCache.count == 0)
        
        memoryCache.set([(String, String)]())
        // memory cache still has no object
        XCTAssert(memoryCache.count == 0)
        
        let objectCount = 1000
        let size = 8 * objectCount
        let keyValuePairs = insertDummyData(into: memoryCache, ofCount: objectCount)
        let keys = keyValuePairs.map { $0.0 }
        let objects = keyValuePairs.map { $0.1 }
        XCTAssert(memoryCache.count == objectCount)
        XCTAssert(memoryCache.size == size)
        memoryCache.objects(by: keys).enumerated().forEach { (key: Int, object: Int?) -> Void in
            XCTAssert(object == objects[key])
        }
        
        memoryCache.remove(keys)
        XCTAssert(memoryCache.count == 0)
        XCTAssert(memoryCache.size == 0)
    }
    
    func testMemoryWarningHandling() throws {
        memoryCache.removeAllOnMemoryWarning = true
        
        // insert 100 objects
        let count = 100
        insertDummyData(into: memoryCache, ofCount: count)
        // make sure inserted
        XCTAssert(memoryCache.count == count)
        
        // inject a notification center
        let center = NotificationCenter()
        memoryCache.notificationCenter = center
        // post fake notification
        center.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // memory cache should be empty now
        XCTAssert(memoryCache.count == 0)
    }
    
    func testEnteringBackgroundHandling() throws {
        memoryCache.removeAllWhenIntoBackground = true
        
        // insert 100 objects
        let count = 100
        insertDummyData(into: memoryCache, ofCount: count)
        // make sure inserted
        XCTAssert(memoryCache.count == count)
        
        // inject a notification center
        let center = NotificationCenter()
        memoryCache.notificationCenter = center
        // post fake notification
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // memory cache should be empty now
        XCTAssert(memoryCache.count == 0)
    }
    
    func testTrimToSize() throws {
        var trimInfo = MemoryCache.TrimInfo()
        let linkedMap = LinkedMap()
        
        // insert 5 nodes, each of size 8 bytes, which is 40 bytes in total
        let sizePerObject = 8
        let count = 5
        
        // set size limit to 16, allowing 2 objects
        let countLimit = 2
        trimInfo.sizeLimit = countLimit * sizePerObject
        
        let keys = (0..<count).map(String.init)
        keys.forEach {
            let node = LinkedMap.Node(key: $0)
            node.size = sizePerObject
            linkedMap.insertNodeAtHead(node)
        }
        
        let nodesToRemove = trimInfo.nodesToRemove(from: linkedMap)
        XCTAssert(
            nodesToRemove.count == count - countLimit
        )
        XCTAssert(  // the order is exactly the same as they were inserted
            nodesToRemove.map(\.key) == [String](keys[0..<(count - countLimit)])
        )
    }
    
    func testTrimToCount() throws {
        let linkedMap = LinkedMap()
        var trimInfo = MemoryCache.TrimInfo()
        
        // allow 2 objects
        let countLimit = 2
        trimInfo.countLimit = countLimit
        
        let count = 5
        let keys = (0..<count).map(String.init)
        keys.forEach {
            linkedMap.insertNodeAtHead(.init(key: $0))
        }
        
        let nodesToRemove = trimInfo.nodesToRemove(from: linkedMap)
        
        XCTAssert(nodesToRemove.count == count - countLimit)
        XCTAssert(  // the order is exactly the same as they were inserted
            nodesToRemove.map(\.key) == [String](keys[0..<(count - countLimit)])
        )
    }
    
    func testTrimToAge() throws {
        let linkedMap = LinkedMap()
        var trimInfo = MemoryCache.TrimInfo()
        
        // allow node not older than 1 sec, say 2 nodes
        let countLimit = 2
        trimInfo.ageLimit = 1
        
        let count = 5
        let keys = (0..<count).map(String.init)
        
        // set a very early access time for the disallowed nodes
        keys[0..<(count-countLimit)].forEach {
            let node = LinkedMap.Node(key: $0)
            node.accessTime = 1  // a very old node
            linkedMap.insertNodeAtHead(node)
        }
        // use default access time, which is `.now`, for the allowed nodes
        keys[(count-countLimit)...].forEach {
            linkedMap.insertNodeAtHead(.init(key: $0))
        }
        
        let nodesToRemove = trimInfo.nodesToRemove(from: linkedMap)
        
        XCTAssert(nodesToRemove.count == count - countLimit)
        XCTAssert(  // the order is exactly the same as they were inserted
            nodesToRemove.map(\.key) == [String](keys[0..<(count - countLimit)])
        )
    }
}


private extension MemoryCacheTests {
    @discardableResult func insertDummyData(
        into memoryCache: MemoryCache,
        ofCount count: Int
    ) -> [(String, Int)] {
        let keys = (0..<count).map(String.init)
        let objects = (0..<count)
        let pairs = [(String, Int)](zip(keys, objects))
        memoryCache.set(pairs)
        return pairs
    }
}
