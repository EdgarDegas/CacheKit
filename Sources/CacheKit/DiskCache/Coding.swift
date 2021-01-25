//
//  Coding.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/21.
//

import Foundation

public typealias NSCodable = NSObject & NSSecureCoding

public protocol Coding {
    func encode<Object: Codable>(_ codable: Object) throws -> Data
    func decode<Object: Codable>(_ encoded: Data) throws -> Object
    
    func nsEncode(_ nsCoding: NSCodable) throws -> Data
    func nsDecode<Object: NSCodable>(_ encoded: Data) throws -> Object
}

final class Coder: Coding {
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()
    
    public func encode<Object: Codable>(_ codable: Object) throws -> Data {
        try encoder.encode(codable)
    }
    
    public func nsEncode(_ nsCodable: NSCodable) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: nsCodable, requiringSecureCoding: true)
    }
    
    public func decode<Object: Codable>(_ encoded: Data) throws -> Object {
        try decoder.decode(Object.self, from: encoded)
    }
    
    public func nsDecode<Object: NSCodable>(_ encoded: Data) throws -> Object {
        guard let decoded = (
            try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: encoded)
        ) else {
            throw Error(objectType: Object.self)
        }
        return decoded
    }
    
    struct Error: LocalizedError {
        private let objectType: AnyObject.Type
        
        var errorDescription: String? {
            "Failed to unarchive data into \(objectType) object."
        }
        
        init(objectType: AnyObject.Type) {
            self.objectType = objectType
        }
    }
}
