//
//  Logger.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/29.
//

import Foundation
import OSLog

protocol Logging {
    func logFault(
        _ message: String,
        on category: LogCategory
    )
}

enum LogCategory {
    case memory
    case disk
}

let defaultLogger: Logging = {
    if #available(iOS 14, *) {
        return Logger.shared
    } else {
        return LegacyLogger.shared
    }
}()

struct LegacyLogger: Logging {
    private let memoryCacheLog = OSLog(subsystem: .uniqueID, category: "MemoryCache")
    private let diskCacheLog = OSLog(subsystem: .uniqueID, category: "DiskCache")
    
    static let shared = LegacyLogger()
    
    func logFault(_ message: String, on category: LogCategory) {
        let log: OSLog = {
            switch category {
            case .memory:
                return memoryCacheLog
            case .disk:
                return diskCacheLog
            }
        }()
        os_log("%s", log: log, type: .fault, message)
    }
}

@available(iOS 14.0, *)
struct Logger: Logging {
    private let memoryCacheLogger = os.Logger(
        subsystem: .uniqueID, category: "MemoryCache")

    private let diskCacheLogger = os.Logger(
        subsystem: .uniqueID, category: "DiskCache")
    
    static let shared = Logger()
    
    func logFault(
        _ message: String,
        on category: LogCategory
    ) {
        let logger: os.Logger = {
            switch category {
            case .disk:
                return diskCacheLogger
            case .memory:
                return memoryCacheLogger
            }
        }()
        logger.fault("\(message)")
    }
}
