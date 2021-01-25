//
//  TrimableTests.swift
//  CacheKitTests
//
//  Created by iMoe Nya on 2021/1/18.
//

import XCTest
@testable import CacheKit

class TrimableTests: XCTestCase {
    
    var testTrimableObject: TestTrimableType!

    override func setUpWithError() throws {
        testTrimableObject = TestTrimableType()
    }

    func testAutoTrim() {
        let expectation = XCTestExpectation()
        let expectedTrimCount = 4
        let waitTime = TimeInterval(expectedTrimCount) * testTrimableObject.trimInfo.autoTrimInterval
        testTrimableObject.trim()
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime + 0.5) {
            self.testTrimableObject = nil
            expectation.fulfill()
            XCTAssert(trimCount == expectedTrimCount)
        }
        wait(for: [expectation], timeout: waitTime + 1)
    }
}

/// For test.
private var trimCount = 0

extension TrimableTests {
    final class TestTrimableType: Trimable {
        var count: Int = 0
        
        var size: Int = 0
        
        var trimInfo = TrimInfo()
        
        var trimQueue = DispatchQueue(label: "test trimable type queue")
        
        func performTrim(with trimInfo: TrimInfo) {
            trimCount += 1
        }
        
        struct TrimInfo: TrimInfoProtocol {
            var sizeLimit: Int = .max
            
            var countLimit: Int = .max
            
            var ageLimit: Int = .max
            
            var autoTrimInterval: TimeInterval = 1
        }
    }
}
