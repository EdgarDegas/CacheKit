//
//  Trimable.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/1.
//

import Foundation

/// Every `Trimable` instance should have info about the size, count and age limit,
/// also the interval between recurring trim operations.
protocol TrimInfoProtocol {
    /// The size limit of all objects stored in a  `Trimable` container.
    var sizeLimit: Int { get }
    /// The count limit of all objects stored in a  `Trimable` container.
    var countLimit: Int { get }
    /// The age limit of all objects stored in a  `Trimable` container, in seconds.
    var ageLimit: Int { get }
    /// The interval between recurring trim operations.
    var autoTrimInterval: TimeInterval { get }
}


/// Instance is trimable to
protocol Trimable {
    /// Define your own `TrimInfo`.
    associatedtype TrimInfo: TrimInfoProtocol
    
    /// Number of objects.
    var count: Int { get }
    
    /// Total size of all the objects.
    var size: Int { get }
    
    /// The trim info instance of your own `TrimInfo` type.
    var trimInfo: TrimInfo { get }
    
    /// The queue to perform trim operations.
    ///
    /// Trim operations are going to delete objects. So choose the queue wisely. Usually you return the
    /// serial queue you used for read / write operations.
    var trimQueue: DispatchQueue { get }
    
    /// Ask the cache interface to trim resources.
    ///
    /// By default, this method async into a global queue with a background level of QOS, delay for a period, then
    /// call the `performTrim(with:)` inside `trimQueue`. The length of the delay period is provided by
    /// `trimInfo`. After that, it calls itself again to restart this cycle.
    func trim()
    
    /// Call `trim()` instead of this method to trim resources. `trim()` calls this method
    /// in `trimQueue`.
    func performTrim(with trimInfo: TrimInfo)
}

extension Trimable where Self: AnyObject {
    func trim() {
        DispatchQueue.global(qos: .background).asyncAfter(
            // wait for `autoTrimInterval` seconds:
            deadline: .now() + trimInfo.autoTrimInterval
        ) { [weak self] in
            guard let self = self else { return }
            self.trimQueue.async { [weak self] in
                guard let self = self else { return }
                self.performTrim(with: self.trimInfo)
            }
            // start the cycle again:
            self.trim()
        }
    }
}
