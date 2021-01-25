//
//  LinkedMapTests.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2021/1/25.
//

import XCTest
@testable import CacheKit

class LinkedMapTests: XCTestCase {
    
    typealias Node = LinkedMap.Node
    
    var linkedMap: LinkedMap!

    override func setUpWithError() throws {
        linkedMap = LinkedMap()
    }
    
    func testInsertionAndRemoval() {
        // insert node1
        let key1 = "1"
        let node1 = Node(key: key1)
        linkedMap.insertNodeAtHead(node1)
        
        XCTAssert(
            // node1 is the only node, so it's the head and the tail
            linkedMap.head == node1 &&
                linkedMap.tail == node1
        )
        XCTAssert(linkedMap.count == 1)
        XCTAssert(linkedMap.contains(key1))
        
        // node retrieved by key1 should be node1 of course
        let retrieved = linkedMap[key1]
        XCTAssert(
            retrieved == node1
        )
        
        // insert node2
        let key2 = "2"
        let node2 = Node(key: key2)
        linkedMap.insertNodeAtHead(node2)
        XCTAssert(linkedMap.count == 2)
        
        // then the later node2 should be head, node1 is the tail
        XCTAssert(linkedMap.head == node2)
        XCTAssert(linkedMap.tail == node1)
        
        // and node2's next is node1, node1's previous is node2
        XCTAssert(node2.next == node1)
        XCTAssert(node1.previous == node2)
        
        // remove node1, then the node2 should be the head and the tail
        linkedMap.remove(node1)
        XCTAssert(linkedMap.head == node2)
        XCTAssert(linkedMap.tail == node2)
        XCTAssert(linkedMap.count == 1)
        
        // remove all nodes
        linkedMap.removeAll()
        XCTAssertNil(linkedMap.head)
        XCTAssertNil(linkedMap.tail)
        XCTAssert(linkedMap.count == 0)
    }
    
    func testBatchInsertion() {
        // insert 100 nodes
        let count = 100
        let keys = (0..<count).map(String.init)
        let nodes = keys.map { Node(key: $0) }
        
        // insert the 100 nodes in two batches, to test
        // whether there is any existing node before insertion
        linkedMap.insertNodesAtHead(
            [Node](nodes[0..<(count / 2)])
        )
        linkedMap.insertNodesAtHead(
            [Node](nodes[(count / 2)...])
        )
        
        XCTAssert(linkedMap.count == count)
        
        // if there is not any existing key, the last node inserted becomes the head
        XCTAssert(
            linkedMap.head == nodes.last
        )
        
        XCTAssert(  // and the first node inserted is the tail
            linkedMap.tail == nodes.first
        )
        
        // and all the nodes are now bidirectionally linked
        nodes.enumerated().forEach { index, node in
            if index - 1 >= 0 {
                XCTAssert(
                    node.next == nodes[index - 1]
                )
            }
            if index + 1 < count {
                XCTAssert(
                    node.previous == nodes[index + 1]
                )
            }
        }
        
        // bring nodes[1] to head
        let newHeadIndex = 1
        let newHead = nodes[newHeadIndex]
        linkedMap.bringNodeToHead(newHead)
        XCTAssert(linkedMap.head == newHead)
        // the next node of the new head is the previous head
        XCTAssert(newHead.next == nodes.last)
        // the node before the tail is now nodes[2]
        XCTAssert(linkedMap.tail?.previous == nodes[newHeadIndex + 1])
        
        // bring the tail to head
        let previousTail = nodes.first!
        linkedMap.bringNodeToHead(previousTail)
        XCTAssert(linkedMap.head == previousTail)
        // the next node of head, is the previous head
        XCTAssert(linkedMap.head?.next == nodes[newHeadIndex])
        // now the tail is the nodes[2]
        XCTAssert(linkedMap.tail == nodes[newHeadIndex + 1])
    }
    
    func testRetrieval() {
        let key = "Key"
        let node = Node(key: "Key")
        let time = 2
        node.accessTime = time
        linkedMap.insertNodeAtHead(node)
        XCTAssert(linkedMap[key] == node)
        XCTAssertNil(  // should return nil if retrieve with a random key
            linkedMap["non-existing"]
        )
    }
    
    func testRemovingMiddleNode() {
        let node1 = Node(key: "1")
        let node2 = Node(key: "2")
        let node3 = Node(key: "3")
        
        linkedMap.insertNodesAtHead([node3, node2, node1])
        XCTAssert(linkedMap.head == node1)
        XCTAssert(linkedMap.tail == node3)
        XCTAssert(node1.next == node2)
        XCTAssert(node2.next == node3)
        XCTAssert(node3.previous == node2)
        XCTAssert(node2.previous == node1)
        
        linkedMap.remove(node2)
        XCTAssert(linkedMap.head == node1)
        XCTAssert(linkedMap.tail == node3)
        XCTAssert(node1.next == node3)
        XCTAssert(node3.previous == node1)
    }
    
    func testRemovingHead() {
        let node1 = Node(key: "1")
        let node2 = Node(key: "2")
        let node3 = Node(key: "3")
        
        linkedMap.insertNodesAtHead([node3, node2, node1])
        XCTAssert(linkedMap.head == node1)
        XCTAssert(linkedMap.tail == node3)
        XCTAssert(node1.next == node2)
        XCTAssert(node2.next == node3)
        XCTAssert(node3.previous == node2)
        XCTAssert(node2.previous == node1)
        
        linkedMap.remove(node1)
        XCTAssert(linkedMap.head == node2)
        XCTAssert(linkedMap.tail == node3)
        XCTAssert(node2.next == node3)
        XCTAssert(node3.previous == node2)
    }
}
