//
//  TestLogger.swift
//  CacheKit
//
//  Created by iMoe Nya on 2021/1/15.
//

import Foundation
@testable import CacheKit

final class TestLogger: Logging {
    var logCount = 0
    var lastMessage: String?
    
    func logFault(_ message: String, on category: LogCategory) {
        logCount += 1
        lastMessage = message
    }
}
