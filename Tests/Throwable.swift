//
//  Throwable.swift
//  CacheKit
//
//  Created by Yiming.Sun on 2021/1/8.
//

import Foundation

/// Throw any error you specified.
protocol Throwable {
    /// The error to throw when `tryThrow` is called, if not overriden.
    var errorToThrow: Error? { get }
    
    /// Set a non-zero number to allow certain times of success before we throw the error you gave.
    var numberOfSuccessBeforeThrowingError: Int { get }
    
    /// This var logs the times of success(es).
    var successCount: Int { get set }
    
    /// Wrap your function call with this, so that we can throw the error you specified.
    ///
    /// - Parameters:
    ///     - error: You can provide a non-nil value to override the `errorToThrow`.
    ///     - closure: The function you originally need to call.
    ///
    /// - Throws: The error you passed in at the `error` parameter. If that is nil, the `errorToThrow` property
    /// will be thrown. If that is nil again, no error is thrown.
    ///
    /// - Returns: The result of the `closure`.
    func tryThrow<Result>(_ error: Error?, _ closure: () throws -> Result) throws -> Result
    
    /// By default, `tryThrow(_:_:)` calls this method to +1 the `successCount`.
    ///
    /// I cannot provide implementation of this function, due to some weired Swift (5.3) immutability issues.
    func incrementSuccessCount()
}

extension Throwable {
    func tryThrow<Result>(_ error: Error? = nil, _ closure: () throws -> Result) throws -> Result {
        func letItGo() throws -> Result {
            incrementSuccessCount()
            return try closure()
        }
        
        guard successCount >= numberOfSuccessBeforeThrowingError else {
            return try letItGo()
        }
        
        if let error = error {
            throw error
        } else if let errorToThrow = errorToThrow {
            throw errorToThrow
        } else {
            return try letItGo()
        }
    }
    
    mutating func incrementSuccessCount() {
        self.successCount += 1
    }
}
