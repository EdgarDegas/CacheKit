//
//  String+Extensions.swift
//  Cache
//
//  Created by iMoe Nya on 2020/11/25.
//

import Foundation

extension String {
    static var uniqueID: String {
        "com.iMoe.Cache"
    }
    
    static func uniqueID(suffixedBy suffix: String) -> String {
        "\(uniqueID).\(suffix)"
    }
}
