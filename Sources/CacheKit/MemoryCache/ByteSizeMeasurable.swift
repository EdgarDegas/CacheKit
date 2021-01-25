//
//  ByteSizeMeasurable.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/22.
//

import Foundation

/// Objects that can provide size information for `MemoryCache`.
///
/// Conform type of the objects you want to store into `MemoryCache`,
/// so that `MemoryCache` can measure the memory usage and trim less
/// recently used objects according to the size limit.
public protocol ByteSizeMeasurable {
    /// How many memory the object takes, in byte(s).
    ///
    /// Make sure no expensive calculation happens here.
    var sizeInByte: Int { get }
}

/// Size of fixed-size trivial types.
enum CachedByteSize {
    static var int: Int = {
        MemoryLayout<Int>.size
    }()
    
    static var int8: Int = {
        MemoryLayout<Int8>.size
    }()
    
    static var int16: Int = {
        MemoryLayout<Int16>.size
    }()
    
    static var int32: Int = {
        MemoryLayout<Int32>.size
    }()
    
    static var int64: Int = {
        MemoryLayout<Int64>.size
    }()
    
    static var float: Int = {
        MemoryLayout<Float>.size
    }()
    
    static var double: Int = {
        MemoryLayout<Double>.size
    }()
    
    @available(iOS 14.0, *)
    static var float16: Int = {
        MemoryLayout<Float16>.size
    }()
    
    static var float80: Int = {
        MemoryLayout<Float80>.size
    }()
    
    static var character: Int = {
        MemoryLayout<Character>.size
    }()
}

extension Int: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int
    }
}

extension Int8: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int8
    }
}

extension Int16: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int16
    }
}

extension Int32: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int32
    }
}

extension Int64: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int64
    }
}

extension UInt: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int
    }
}

extension UInt8: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int8
    }
}

extension UInt16: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int16
    }
}

extension UInt32: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int32
    }
}

extension UInt64: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.int64
    }
}

extension Float: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.float
    }
}

@available(iOS 14.0, *)
extension Float16: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.float16
    }
}

extension Double: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.double
    }
}

extension Float80: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.float80
    }
}

extension Character: ByteSizeMeasurable {
    public var sizeInByte: Int {
        CachedByteSize.character
    }
}

extension String: ByteSizeMeasurable {
    public var sizeInByte: Int {
        count * CachedByteSize.character
    }
}

extension Array: ByteSizeMeasurable where Element: ByteSizeMeasurable {
    public var sizeInByte: Int {
        reduce(0) { $0 + $1.sizeInByte }
    }
}
