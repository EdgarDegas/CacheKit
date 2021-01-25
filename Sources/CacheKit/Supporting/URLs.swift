//
//  URLs.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/24.
//

import Foundation

enum URLs {
    static var cache: URL {
        FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask)
            .first!
    }
}
