//
//  FileStorageProtocol.swift
//  CacheKit
//
//  Created by iMoe Nya on 2021/1/9.
//

import Foundation

public protocol FileStorageProtocol: InitializableFromURL {
    static var filesDirectoryName: String { get }
    static var trashDirectoryName: String { get }
    var throwsWhenDeletingNonExistingFile: Bool { get }
    var filesURL: URL { get }
    var trashURL: URL { get }
    func file(by name: String) throws -> Data?
    func write(_ data: Data, named name: String) throws
    func deleteFile(named name: String) throws
    func deleteFiles(named names: [String]) throws
    func deleteAll() throws
    func emptyTrash()
}

public enum FileStorageError: Error {
    /// Failed to create a subdirectory.
    case failedCreatingDirectory(_ error: Error)
    /// The file does not exist.
    case noSuchFile
    /// File errors except _file not exist_, which is enumerated as the `noSuchFile` error..
    case fileError(_ cocoaError: CocoaError)
    /// iCloud related file error.
    case ubiquitousFileError(_ cocoaError: CocoaError)
    /// Other not covered errors.
    case underlying(_ error: Swift.Error)
}
