//
//  LinkedMap.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/1.
//

import Foundation


/// A bidirectional linked list and a hash map.
///
/// ```plaintext
/// head                                tail
///  |                                   |
///  ↓                                   ↓
/// node ---(next)--> node ---(next)--> node
///  1   <--(prev)---  2   <--(prev)---  3
///
/// ```
///
final class LinkedMap {
    
    typealias Key = String
    
    /// Hashmap from key to every node.
    ///
    /// Use subscript to get node from this linked map, so that the access time of the node
    /// can get updated.
    private var dictionary = [Key: Node]()
    
    /// Memory cost of all nodes.
    var size: Int = 0
    
    /// Total amount of nodes.
    var count: Int = 0
    
    /// The most recently accessed node.
    var head: Node?
    
    /// The least recently accessed node.
    var tail: Node?
    
    /// Add a node at head, which now becomes the most recently accessed.
    func insertNodeAtHead(_ node: Node) {
        dictionary[node.key] = node
        size += node.size
        count += 1
        if let previousHead = head {
            node.next = previousHead
            previousHead.previous = node
            head = node
        } else {
            head = node
            tail = node
        }
    }
    
    /// Add nodes at head. The last node of the array becomes the head.
    func insertNodesAtHead(_ nodes: [Node]) {
        guard !nodes.isEmpty else { return }
        
        // connect nodes to the linked list:
        if let previousHead = head {
            // attach the first node onto the original head:
            nodes.first!.next = previousHead
            previousHead.previous = nodes.first!
            // update head:
            head = nodes.last!
        } else {  // if there was no node:
            head = nodes.last!
            tail = nodes.first!
        }
        
        count += Int(nodes.count)
        for (index, node) in nodes.enumerated() {
            dictionary[node.key] = node
            size += node.size
            if index != 0 {
                node.next = nodes[index - 1]
            }
            if index != nodes.count - 1 {
                node.previous = nodes[index + 1]
            }
        }
    }
    
    /// If the linked map contains a node of key.
    func contains(_ key: Key) -> Bool {
        dictionary.keys.contains(key)
    }
    
    /// Get a node by key.
    subscript(_ key: Key) -> Node? {
        get {
            guard let node = dictionary[key] else {
                return nil
            }
            return node
        }
        // not allow set
    }
    
    /// Make the node the new head, which means it is the most recently accessed.
    func bringNodeToHead(_ node: Node) {
        guard head != node else { return }
        if tail == node {
            tail = node.previous
            tail?.next = nil
        } else {
            node.next?.previous = node.previous
            node.previous?.next = node.next
        }
        node.next = head
        node.previous = nil
        head?.previous = node
        head = node
    }
    
    /// Remove a node.
    func remove(_ node: Node) {
        dictionary.removeValue(forKey: node.key)
        count -= 1
        size -= node.size
        if let next = node.next {
            next.previous = node.previous
        }
        if let previous = node.previous {
            previous.next = node.next
        }
        if head == node {
            head = node.next
        }
        if tail == node {
            tail = node.previous
        }
    }
    
    /// Remove all nodes.
    func removeAll() {
        guard dictionary.count > 0 else { return }
        count = 0
        size = 0
        head = nil
        tail = nil
        dictionary.removeAll()
    }
}

extension LinkedMap {
    /// A node of `LinkedMap`.
    final class Node: Equatable {
        static func == (lhs: LinkedMap.Node, rhs: LinkedMap.Node) -> Bool {
            lhs === rhs
        }
        
        var previous: Node?
        var next: Node?
        var key: Key
        var value: Any?
        var accessTime: Int = .now
        var size: Int = 0
        
        init(key: Key) {
            self.key = key
        }
        
        var age: Int {
            Int.now - accessTime
        }
    }
}

extension LinkedMap: CustomDebugStringConvertible {
    var debugDescription: String {
        var node = head
        guard node != nil else { return "(empty)" }
        var keys = [String]()
        while let current = node {
            defer {
                node = current.next
            }
            keys.append(current.key)
        }
        return keys.joined(separator: " -> ")
    }
}
