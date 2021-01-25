//
//  FileManagerWrapperTests.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2020/12/16.
//

import XCTest
@testable import CacheKit

class FileManagerWrapperTests: XCTestCase {
    
    var fileManager: TestFileManager!
    var fileManagerDelegate: FileManagerDelegate!
    
    var fileStorageURL: URL!
    var filesURL: URL!
    var trashURL: URL!
    
    var fileStorage: FileManagerWrapper!
    
    override func setUpWithError() throws {
        let url = URLs.cache.appendingPathComponent(UUID().uuidString)
        try! TestFileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true)
        fileStorageURL = url
        filesURL = url.appendingPathComponent(FileManagerWrapper.filesDirectoryName)
        trashURL = url.appendingPathComponent(FileManagerWrapper.trashDirectoryName)
        
        fileStorage = try! FileManagerWrapper(url: fileStorageURL)
        
        TestFileManager.default.createFile(
            atPath: fileStorage.filesURL.appendingPathComponent("file").path,
            contents: .init(),
            attributes: nil)
        
        // you can inject this fileManager into fileStorage for some tests:
        fileManager = TestFileManager()
        fileManagerDelegate = .init()
        fileManager.delegate = fileManagerDelegate
    }
    
    func testRead() throws {
        let nonExistingFilename = "non-existing"
        XCTAssertNil(try fileStorage.file(by: nonExistingFilename))
        
        let filename = "file"
        XCTAssertNotNil(try fileStorage.file(by: filename))
    }
    
    func testWrite() throws {
        let filename = "test write"
        let content = "test write content"
        let contentData = content.data(using: .utf8)!
        let fileURL = fileStorage.filesURL.appendingPathComponent(filename)
        try fileStorage.write(contentData, named: filename)
        XCTAssert(fileManager.fileExists(atPath: fileURL.path))
        XCTAssert(fileManager.contents(atPath: fileURL.path) == contentData)
        XCTAssert(try! Data(contentsOf: fileURL) == contentData)
    }
    
    func testDeletion() throws {
        XCTAssert(fileManager.fileExists(atPath: filesURL.appendingPathComponent("file").path))
        
        // move files/file into trash/:
        XCTAssertNoThrow(
            try fileStorage.deleteFile(named: "file")
        )
        
        // files/file should be removed:
        XCTAssertFalse(fileManager.fileExists(atPath: filesURL.appendingPathComponent("file").path))
        
        // check existense of trash/file:
        XCTAssert(fileManager.fileExists(atPath: trashURL.appendingPathComponent("file").path))
        
        // recover files/file:
        TestFileManager.default.createFile(atPath: filesURL.appendingPathComponent("file").path, contents: .init())
        
        // again, move another file files/file into trash/, which
        // normally causes an error since there's alreay a file named __file__ under trash/,
        // but that error should be handled under the hood, instead of thrown
        XCTAssertNoThrow(
            try fileStorage.deleteFile(named: "file")
        )
    }
    
    func testDeletingNonExistingFile() throws {
        fileStorage.throwsWhenDeletingNonExistingFile = true
        XCTAssertThrowsError(
            try fileStorage.deleteFile(named: "non-existing")
        ) {
            if case .noSuchFile = $0 as! FileStorageError {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
        }
        
        fileStorage.throwsWhenDeletingNonExistingFile = false
        XCTAssertNoThrow(
            try fileStorage.deleteFile(named: "non-existing")
        )
    }
    
    func testDeletingMultipleFiles() throws {
        let filenames = createDummyFiles(inside: filesURL)
        try fileStorage.deleteFiles(named: filenames)
        filenames.forEach {
            XCTAssertFalse(
                TestFileManager.default.fileExists(atPath: filesURL.appendingPathComponent($0).path)
            )
        }
    }
    
    func testDeinit() throws {
        let fileURL = fileStorage!.filesURL
        let trashURL = fileStorage!.trashURL
        fileStorage = nil
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            XCTAssertFalse(TestFileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertFalse(TestFileManager.default.fileExists(atPath: trashURL.path))
        }
    }
    
    // MARK: tests with Injected File Storage
    func testThrowingDifferentErrorsWhenDeleting() throws {
        fileStorage.fileManager = fileManager
        do {  // try throwing ubiquitous file error
            let errorCode = CocoaError.ubiquitousFileUnavailable
            fileManager.errorToThrow = CocoaError(errorCode)
            XCTAssertThrowsError(
                try fileStorage.deleteFile(named: "file")
            ) {
                if case FileStorageError.ubiquitousFileError(let cocoaError) = $0 {
                    XCTAssert(cocoaError.code == errorCode)
                } else {
                    XCTAssert(false)
                }
            }
        }
        
        do {  // try throwing other file error
            let errorCode = CocoaError.fileReadUnknown
            fileManager.errorToThrow = CocoaError(errorCode)
            XCTAssertThrowsError(
                try fileStorage.deleteFile(named: "file")
            ) {
                if case FileStorageError.fileError(let cocoaError) = $0 {
                    XCTAssert(cocoaError.code == errorCode)
                } else {
                    XCTAssert(false)
                }
            }
        }
        
        do {  // try throwing other cocoa error
            let errorCode = CocoaError.coderInvalidValue
            fileManager.errorToThrow = CocoaError(errorCode)
            XCTAssertThrowsError(
                try fileStorage.deleteFile(named: "file")
            ) {
                if case FileStorageError.underlying(let cocoaError as CocoaError) = $0 {
                    XCTAssert(cocoaError.code == errorCode)
                } else {
                    XCTAssert(false)
                }
            }
        }
        
        do {  // try throwing random error
            fileManager.errorToThrow = NSError(domain: "random", code: 0, userInfo: nil)
            XCTAssertThrowsError(
                try fileStorage.deleteFile(named: "file")
            ) {
                if case FileStorageError.underlying(let error as NSError) = $0 {
                    XCTAssert(error.domain == "random")
                } else {
                    XCTAssert(false)
                }
            }
        }
    }
    
    func testRollbackWhenDeletingMultipleFiles() throws {
        fileStorage.fileManager = fileManager
        let filenames = createDummyFiles(inside: filesURL)
        fileManager.errorToThrow = NSError(domain: "random", code: 0, userInfo: nil)
        fileManager.numberOfSuccessBeforeThrowingError = 20
        try fileStorage.deleteFiles(named: filenames)
        filenames.forEach {
            XCTAssert(
                TestFileManager.default.fileExists(atPath: filesURL.appendingPathComponent($0).path)
            )
        }
    }
    
    func testDeleteAll() throws {
        fileStorage.fileManager = fileManager
        createDummyFiles(inside: fileStorage.filesURL)
        try fileStorage.deleteAll()
        XCTAssert(
            try fileManager.contentsOfDirectory(
                at: fileStorage.filesURL,
                includingPropertiesForKeys: nil)
                .isEmpty
        )
    }
    
    func testWritingTrashWhileDeleting() throws {
        fileStorage.fileManager = fileManager
        fileStorage.emptyTrash()
        try fileStorage.deleteFile(named: "file")
        try fileStorage.write(.init(), named: "new")
        fileStorage.emptyTrash()
        try fileStorage.deleteFile(named: "new")
    }
    
    func testEmptyTrash() {
        createDummyFiles(inside: fileStorage.trashURL)
        fileStorage.emptyTrash()
        let waitingTime: TimeInterval = 2
        let expectation = XCTestExpectation(description: "There should not be any trash left.")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + waitingTime) { [self] in
            if try! fileManager.contentsOfDirectory(
                at: fileStorage.trashURL,
                includingPropertiesForKeys: nil
            ).count == 0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: waitingTime + 1, enforceOrder: false)
    }
}


extension FileManagerWrapperTests {
    @discardableResult func createDummyFiles(inside url: URL) -> [String] {
        var filenames = [String]()
        (0..<100)  // create 100 files named 0, 1, 2, ..., 99
            .lazy
            .map {
                let name = "\($0)"
                filenames.append(name)
                return name
            }
            .forEach {
                fileManager.createFile(
                    atPath: url.appendingPathComponent($0).path,
                    contents: .init(),
                    attributes: nil)
            }
        return filenames
    }
    
    class FileManagerDelegate: NSObject, Foundation.FileManagerDelegate {
        func fileManager(
            _ fileManager: Foundation.FileManager,
            shouldProceedAfterError error: Error,
            movingItemAt srcURL: URL,
            to dstURL: URL
        ) -> Bool {
            print("error moving from \(srcURL) to \(dstURL): \(error)")
            return false
        }
    }
}
