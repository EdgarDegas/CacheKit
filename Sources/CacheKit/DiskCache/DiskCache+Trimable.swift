//
//  DiskCache+Trimable.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/29.
//

import Foundation

extension DiskCache {
    struct TrimInfo: TrimInfoProtocol {
        var autoTrimInterval: TimeInterval = 60
        var sizeLimit = Int.max
        var countLimit = Int.max
        var ageLimit = Int.max
        var freeDiskSpace: Int = 0
        
        /// Returns an as-small-as-posible amount of objects to remove in a trim operation.
        func objectsToRemove<RealmItems: DatabaseObjectSequence>(
            from items: RealmItems,
            currentSize: Int,
            availableCapacity: Int
        ) -> [DatabaseObjectProtocol] {
            let sizeLimit = min(self.sizeLimit, availableCapacity - freeDiskSpace)
            guard  // necessarity check:
                sizeLimit < .max ||
                    countLimit < .max ||
                    ageLimit < .max
            else {
                return [ ]
            }
            
            var currentSize = currentSize
            var currentCount = items.count
            var toReturn = [DatabaseObjectProtocol]()
            for item in items {
                guard currentSize > sizeLimit ||
                        currentCount > countLimit ||
                        item.age() > ageLimit
                else {
                    break
                }
                toReturn.append(item)
                currentSize -= item.size
                currentCount -= 1
            }
            return toReturn
        }
    }
}
