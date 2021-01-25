//
//  InitializableFromURL.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/2.
//

import Foundation

/// Types that can be initialized from a URL.
public protocol InitializableFromURL {
    init(url: URL) throws
}
