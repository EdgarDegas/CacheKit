//
//  TestFMDatabase.swift
//  CacheKit
//
//  Created by iMoe Nya on 2021/1/18.
//

import Foundation
import FMDB

class TestFMDatabase: FMDatabase, Throwable {
    var errorToThrow: Error?
    var numberOfSuccessBeforeThrowingError = 0
    var successCount = 0

    override func lastError() -> Error {
        errorToThrow ?? NSError(domain: "no error", code: 0, userInfo: nil)
    }
    
    override func executeQuery(_ sql: String, values: [Any]?) throws -> FMResultSet {
        try tryThrow {
            try super.executeQuery(sql, values: values)
        }
    }
    
    func incrementSuccessCount() {
        successCount += 1
    }
}
