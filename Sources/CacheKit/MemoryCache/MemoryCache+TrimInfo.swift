//
//  MemoryCache+TrimInfo.swift
//  CacheKit
//
//  Created by iMoe Nya on 2021/1/25.
//

import Foundation

extension MemoryCache {
    public struct TrimInfo: TrimInfoProtocol {
        var autoTrimInterval: TimeInterval = 5
        var sizeLimit: Int = .max
        var countLimit: Int = .max
        var ageLimit: Int = .max
        
        func nodesToRemove(
            from linkedMap: LinkedMap
        ) -> [LinkedMap.Node] {
            guard
                linkedMap.count > 0,
                sizeLimit < .max ||
                    countLimit < .max ||
                    ageLimit < .max
            else {
                return [ ]
            }
            
            var currentSize = linkedMap.size
            var currentCount = linkedMap.count
            var nextNode = linkedMap.tail
            
            var toRemove = [LinkedMap.Node]()
            while
                let currentNode = nextNode,
                currentNode.age > ageLimit ||
                    currentSize > sizeLimit ||
                    currentCount > countLimit
            {
                defer {
                    currentSize -= currentNode.size
                    currentCount -= 1
                    nextNode = currentNode.previous
                }
                toRemove.append(currentNode)
            }
            return toRemove
        }
    }
}
