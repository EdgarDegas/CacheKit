//
//  TestCoder.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2021/1/18.
//

import Foundation
@testable import CacheKit

final class TestCoder: Coding, Throwable {
    private let defaultCoder = Coder()
    
    func incrementSuccessCount() {
        successCount += 1
    }
    
    func encode<Object>(_ codable: Object) throws -> Data where Object : Decodable, Object : Encodable {
        try tryThrow {
            try defaultCoder.encode(codable)
        }
    }
    
    func decode<Object>(_ encoded: Data) throws -> Object where Object : Decodable, Object : Encodable {
        try tryThrow {
            try defaultCoder.decode(encoded)
        }
    }
    
    func nsEncode(_ nsCoding: NSCodable) throws -> Data {
        try tryThrow {
            try defaultCoder.nsEncode(nsCoding)
        }
    }
    
    func nsDecode<Object>(_ encoded: Data) throws -> Object where Object : NSObject, Object : NSSecureCoding {
        try tryThrow {
            try defaultCoder.nsDecode(encoded)
        }
    }
    
    var errorToThrow: Error?
    
    var numberOfSuccessBeforeThrowingError: Int = 0
    
    var successCount: Int = 0
}
