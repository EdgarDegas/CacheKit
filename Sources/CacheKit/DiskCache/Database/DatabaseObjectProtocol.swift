//
//  DatabaseObject.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/20.
//

import Foundation
import func QuartzCore.CACurrentMediaTime

public protocol DatabaseObjectProtocol {
    
    /// Init an object with properties all set to default values.
    init()
    
    /// Init an object with key and value. The size is set according to the bytes count of the value.
    init(key: String, value: Data?)
    
    typealias Key = DatabaseObjectVitalKey
    
    var key: String { get set }
    /// Serialized data of the object. Nil if data is stored as a file.
    var value: Data? { get set }
    var filename: String? { get set }
    var size: Int { get set }
    var accessTime: Int { get set }
    
    /// Time since last access time.
    ///
    /// Use function instead of computing variable to prevent `age` from
    /// being treated as a column in case you are using ORM.
    func age() -> Int
}

extension DatabaseObjectProtocol {
    public func age() -> Int {
        Int.now - accessTime
    }
}

/// Properties of `DatabaseObject`, use `rawValue` of the enumerated cases
/// instead of _magic_ raw strings when referring to their names.
public enum DatabaseObjectVitalKey: String {
    case key
    case value
    case filename
    case size
    case accessTime
}
