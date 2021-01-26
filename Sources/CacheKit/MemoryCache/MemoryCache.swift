//
//  MemoryCache.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/24.
//

import Foundation

import class UIKit.UIApplication
import func QuartzCore.CACurrentMediaTime

/// The default memory cache used by this framework.
open class MemoryCache: Trimable, AnyObjectStoring {
    // MARK: public
    public typealias Key = String
    
    public var removeAllOnMemoryWarning: Bool = true
    
    public var removeAllWhenIntoBackground: Bool = true
    
    public var trimInfo = TrimInfo()
    
    public init(name: String) {
        self.name = name
        beginObservingNotifications(from: notificationCenter)
        trim()
    }
    
    public var count: Int {
        lock.wait()
        defer {
            lock.signal()
        }
        return linkedMap.count
    }
    
    public var size: Int {
        lock.wait()
        defer {
            lock.signal()
        }
        return linkedMap.size
    }
    
    public func contains(_ key: Key) -> Bool {
        lock.wait()
        defer {
            lock.signal()
        }
        return linkedMap.contains(key)
    }
    
    public func object<Object>(by key: Key) -> Object? {
        lock.wait()
        defer {
            lock.signal()
        }
        guard let node = linkedMap[key] else { return nil }
        linkedMap.bringNodeToHead(node)
        node.accessTime = .now
        return node.value as? Object
    }
    
    public func objects<Object>(by keys: [Key]) -> [Object?] {
        lock.wait()
        defer {
            lock.signal()
        }
        return keys.map {
            if let node = linkedMap[$0] {
                node.accessTime = .now
                linkedMap.bringNodeToHead(node)
                return node.value as? Object
            } else {
                return nil
            }
        }
    }
    
    public func set<Object>(_ object: Object, by key: Key) {
        lock.wait()
        defer {
            lock.signal()
        }
        performInserting(object, by: key)
    }
    
    public func set<Object>(_ keyValuePairs: [(Key, Object)]) {
        lock.wait()
        defer {
            lock.signal()
        }
        guard !keyValuePairs.isEmpty else { return }
        guard keyValuePairs.count > 1 else {
            let (key, object) = keyValuePairs.first!
            performInserting(object, by: key)
            return
        }
        performInserting(keyValuePairs)
    }
    
    public func remove(_ key: Key) {
        lock.wait()
        defer {
            lock.signal()
        }
        guard let toRemove = linkedMap[key] else { return }
        linkedMap.remove(toRemove)
    }
    
    public func remove(_ keys: [Key]) {
        keys.forEach(remove)
    }
    
    public func removeAll() {
        linkedMap.removeAll()
    }
    
    // MARK: internal
    typealias Map = LinkedMap
    
    var trimQueue = DispatchQueue(
        label: .uniqueID(suffixedBy: "MemoryCache.TrimQueue"))
    
    let name: String
    
    var notificationCenter: NotificationCenter = .default {
        didSet {
            beginObservingNotifications(from: notificationCenter)
        }
    }
    
    func performTrim(with trimInfo: TrimInfo) {
        lock.wait()
        defer {
            lock.signal()
        }
        trimInfo
            .nodesToRemove(from: linkedMap)
            .forEach {
                linkedMap.remove($0)
            }
    }
    
    // MARK: private
    private let linkedMap = Map()
    
    private var lock = DispatchSemaphore(value: 1)
}


// MARK: - private
private extension MemoryCache {
    /// Insert an object into the linked map.
    ///
    /// This method is not thread safe.
    func performInserting<Object>(_ object: Object, by key: Key) {
        guard let newNode = createNewNodeOrUpdate(of: object, by: key) else { return }
        linkedMap.insertNodeAtHead(newNode)
    }
    
    /// Insert objects into the linked map in batch.
    ///
    /// This method is not thread safe.
    func performInserting<Object>(_ keyValuePairs: [(Key, Object)]) {
        var nodesToInsert = [LinkedMap.Node]()
        keyValuePairs.forEach { key, object in
            guard let newNode = createNewNodeOrUpdate(of: object, by: key) else { return }
            nodesToInsert.append(newNode)
        }
        linkedMap.insertNodesAtHead(nodesToInsert)
    }
    
    /// Returns a `Node` if there is no existing one. This method has a **side effect**: it updates the
    /// existing node with the object.
    ///
    /// This method is not thread safe.
    func createNewNodeOrUpdate<Object>(
        of object: Object, by key: Key
    ) -> LinkedMap.Node? {
        var size: Int = 0
        if let measurable = object as? ByteSizeMeasurable {
            size = measurable.sizeInByte
        }
        if let existingNode = linkedMap[key] {
            linkedMap.size -= existingNode.size
            linkedMap.size += size
            existingNode.accessTime = .now
            existingNode.value = object
            existingNode.size = size
            linkedMap.bringNodeToHead(existingNode)
            return nil
        } else {
            let node = Map.Node(key: key)
            node.value = object
            node.size = size
            return node
        }
    }
    
    func beginObservingNotifications(from center: NotificationCenter) {
        notificationCenter.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.handleMemoryWarning()
        }
        
        notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.handleEnteringBackground()
        }
    }
    
    func handleMemoryWarning() {
        guard removeAllOnMemoryWarning else { return }
        removeAll()
    }
    
    func handleEnteringBackground() {
        guard removeAllWhenIntoBackground else { return }
        removeAll()
    }
}


// MARK: - CustomStringRepresentable
extension MemoryCache: CustomDebugStringConvertible {
    open var debugDescription: String {
        """
        Memory Cache \(name)
        \(size != 0 ? "size: \(size)" : "size not calculated")
        object count: \(count)
        """
    }
}
