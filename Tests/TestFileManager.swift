//
//  TestFileManager.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2021/1/18.
//

import Foundation

class TestFileManager: Foundation.FileManager, Throwable {
    func incrementSuccessCount() {
        successCount += 1
    }
    
    var errorToThrow: Error?
    var numberOfSuccessBeforeThrowingError = 0
    var successCount = 0
    
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try tryThrow {
            try super.moveItem(at: srcURL, to: dstURL)
        }
    }
    
    override func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: TestFileManager.DirectoryEnumerationOptions = []
    ) throws -> [URL] {
        let contents = try super.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
        if !contents.isEmpty {
            print("Contents under \(url.absoluteString):")
        } else {
            print("No content under \(url.absoluteString).")
        }
        contents.forEach {
            print($0.lastPathComponent)
        }
        return contents
    }
}
