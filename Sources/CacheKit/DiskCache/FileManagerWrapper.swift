//
//  FileManagerWrapper.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/25.
//

import Foundation

/// A part of a `DiskCache`.
///
/// `FileManagerWrapper` is not thread safe, and not recommended to be used directly.
/// Instead, use `Cache` or `DiskCache`.
open class FileManagerWrapper: FileStorageProtocol {
    // MARK: - public
    /// The directory name of the files directory.
    public class var filesDirectoryName: String {
        "files"
    }
    
    /// The directory name of the trash directory.
    public class var trashDirectoryName: String {
        "trash"
    }
    
    /// Should deletion methods throw error when the file to be deleted does not
    /// exist. Defaults to `false`.
    public var throwsWhenDeletingNonExistingFile = false
    
    /// Two directories are created under `url`. You can check their URLs at `fileURL` and `trashURL`.
    required public init(url: URL) throws {
        filesURL = url.appendingPathComponent(Self.filesDirectoryName)
        trashURL = url.appendingPathComponent(Self.trashDirectoryName)
        fileManagerDelegate = FileManagerDelegate()
        fileManager = FileManager()
        fileManager.delegate = fileManagerDelegate
        do {
            try fileManager.createDirectory(
                at: filesURL,
                withIntermediateDirectories: true)
            try fileManager.createDirectory(
                at: trashURL,
                withIntermediateDirectories: true)
        } catch {
            throw FileStorageError.failedCreatingDirectory(error)
        }
    }
    
    /// Directory that stores cached files. It's a subdirectory under `url`.
    public let filesURL: URL
    /// Trash directory of deleted file cache. It's a subdirectory under `url`.
    public let trashURL: URL
    
    public func file(by name: String) throws -> Data? {
        try run(throwsNoSuchFileError: false) {
            try Data(contentsOf: urlOfFile(named: name))
        }
    }
    
    public func write(_ data: Data, named name: String) throws {
        try run(throwsNoSuchFileError: true) {
            try data.write(to: urlOfFile(named: name))
        }
    }
    
    public func deleteFile(named name: String) throws {
        try run(throwsNoSuchFileError: throwsWhenDeletingNonExistingFile) {
            try fileManager.moveItem(at: urlOfFile(named: name), to: urlOfTrash(named: name))
        }
    }
    
    public func deleteFiles(named names: [String]) throws {
        var deleted = [String]()
        for name in names {
            do {
                try run(throwsNoSuchFileError: throwsWhenDeletingNonExistingFile) {
                    try deleteFile(named: name)
                    deleted.append(name)
                }
            } catch {  // try to rollback:
                deleted.forEach {
                    // just `try?` to:
                    try? fileManager.copyItem(at: urlOfTrash(named: $0), to: urlOfFile(named: $0))
                }
                break
            }
        }
    }
    
    public func deleteAll() throws {
        try run(throwsNoSuchFileError: throwsWhenDeletingNonExistingFile) {
            try fileManager.contentsOfDirectory(
                at: filesURL,
                includingPropertiesForKeys: nil
            ).forEach {
                let name = $0.lastPathComponent
                try fileManager.moveItem(at: $0, to: urlOfTrash(named: name))
            }
        }
    }
    
    // MARK: - internal
    /// Allow internally inject your own `FileManager` instance.
    var fileManager: FileManager
    
    deinit {
        trashQueue.async { [filesURL] in
            try? FileManager.default.removeItem(at: filesURL)
        }
        trashQueue.async { [trashURL] in
            try? FileManager.default.removeItem(at: trashURL)
        }
    }
    
    /// Remove files under the trash URL, asynchronously.
    public func emptyTrash() {
        // even if `self` is released, still should delete the files:
        trashQueue.async { [trashURL, fileManager] in
            do {
                try? fileManager.contentsOfDirectory(
                    at: trashURL,
                    includingPropertiesForKeys: nil
                )
                .forEach {
                    try? fileManager.removeItem(at: $0)
                }
            }
        }
    }
    
    // MARK: - private
    private lazy var trashQueue: DispatchQueue = {
        .init(
            label: .uniqueID(suffixedBy: "FileManagerWrapper.TrashQueue"),
            qos: .background)
    }()
    
    private let fileManagerDelegate: FileManagerDelegate
}


// MARK: - Private Helpers
private extension FileManagerWrapper {
    func urlOfFile(named name: String) -> URL {
        filesURL.appendingPathComponent(name)
    }
    
    func urlOfTrash(named name: String) -> URL {
        trashURL.appendingPathComponent(name)
    }
    
    /// Run a closure and convert errors thrown by it to `FileStorageError`.
    ///
    /// `throwsNoSuchFileError` allows you to ignore _no such file_ errors, which is useful when reading
    /// or deleting files:
    /// - When reading a nonexisting file, we should simply return `nil`, instead of throwing errors.
    /// - When deleting, if there is no such file, there's actually nothing to do. You can set
    ///   `fileStorage.throwsWhenDeletingNonExistingFile`, which is `false` by default, to true
    ///   so that _no such file_ errors will still be thrown when deleting.
    ///
    /// - Parameters:
    ///     - throwsNoSuchFileError: If false, errors complaining about _no such file_ are ignored.
    ///     - block: The throwing closure to execute.
    /// - Returns: Returns the result of `block` if it succeeded to execute.
    func run<Result>(
        throwsNoSuchFileError: Bool,
        _ block: () throws -> Result
    ) rethrows -> Result? {
        do {
            return try block()
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            guard throwsNoSuchFileError else { return nil }
            throw FileStorageError.noSuchFile
        } catch let error as CocoaError {
            if error.isFileError {
                throw FileStorageError.fileError(error)
            } else if error.isUbiquitousFileError {
                throw FileStorageError.ubiquitousFileError(error)
            } else {
                throw FileStorageError.underlying(error)
            }
        } catch {
            throw FileStorageError.underlying(error)
        }
    }
}


// MARK: - Definitions
extension FileManagerWrapper {
    /// Delegate for the file manager inside `FileManagerWrapper`.
    final class FileManagerDelegate: NSObject, Foundation.FileManagerDelegate {
        func fileManager(
            _ fileManager: FileManager,
            shouldProceedAfterError error: Error,
            movingItemAt srcURL: URL,
            to dstURL: URL
        ) -> Bool {
            if let error = error as? CocoaError,
               error.code == .fileWriteFileExists
            {
                // Usually, error is caused by existence of a file with the
                // same name in `dstURL`. In that case, return `true` so that the file manager
                // will delete the file to be moved and pretend moving has succeeded.
                return true
            } else {
                // Otherwise, return false so that the error can be properly thrown:
                return false
            }
        }
    }
}
