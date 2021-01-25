//
//  SQLiteObject.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/24.
//

import Foundation

public struct SQLiteObject: DatabaseObjectProtocol {
    public var key: String = ""
    
    public var value: Data?
    
    public var filename: String?
    
    public var size: Int = 0
    
    public var accessTime: Int = .now
    
    public init () { }
    
    public init(key: String, value: Data?) {
        self.key = key
        self.value = value
        self.size = Int(value?.count ?? 0)
    }
}
