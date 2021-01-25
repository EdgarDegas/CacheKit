//
//  DatabaseObjectSequence.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/28.
//

import Foundation

/// Iteration of a bunch of `DatabaseObject`s.
///
/// Can be a lazily-queried realm `Results<DatabaseObject>`
/// or a trivial array of `DatabaseStorage.Item`.
public protocol DatabaseObjectSequence: BidirectionalCollection
where Element: DatabaseObjectProtocol
{
    
}

extension Array: DatabaseObjectSequence where Element: DatabaseObjectProtocol { }
