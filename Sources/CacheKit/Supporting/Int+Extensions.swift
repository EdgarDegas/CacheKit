//
//  Int+Extensions.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/20.
//

import func QuartzCore.CACurrentMediaTime

extension Int {
    static var now: Int {
        Int(CACurrentMediaTime())
    }
}
