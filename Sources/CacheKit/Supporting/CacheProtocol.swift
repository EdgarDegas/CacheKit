//
//  CodableKeyValueStorageProtocol.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/1.
//

import Foundation

protocol KeyValueStorageProtocol {
    func contains(_ key: String) -> Bool
    var count: UInt { get }
    var size: UInt { get }
}

protocol CodableKeyValueStorageProtocol: KeyValueStorageProtocol {
    func getObject<Object: Codable>(by key: String) -> Object?
    func set<Object: Codable>(_ object: Object?, by key: String)
}
