//
//  SQLComposing.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/28.
//

import Foundation

/// Definition of a column.
public struct ColumnDefinition {
    let name: String
    let type: String
    var primary: Bool = false
    var nullable: Bool = true
    var indexed: Bool = false
}

/// Used to build SQL statements.
///
/// It's recommended that the functions should not have any side effect
/// in their implementations, which suggests that types conforming
/// to this protocol should have no inner states.
public protocol SQLComposing {
    /// Returns a SQL table creation statement.
    ///
    /// - Parameters:
    ///     - tableName: Name of the table to create.
    ///     - columns: Names of columns of the table.
    ///     - key: The one and only primary key of the table.
    ///     - indices: Indices to create.
    func createTable(
        named tableName: String,
        withColumns columns: [ColumnDefinition]
    ) -> String
    
    func select(
        from tableName: String,
        by column: String,
        amount: Int
    ) -> String
    
    func selectRecords(
        from tableName: String,
        orderedBy column: String,
        ascending: Bool,
        limitedAt limit: Int?
    ) -> String
    
    func selectCount(from tableName: String) -> String
    
    func selectSum(
        from tableName: String,
        of column: String
    ) -> String
    
    /// Returns a SQL insertion statement with column names and question marks as values.
    ///
    /// Before executing this statement, you have to bind values onto the columns.
    func insert(
        into tableName: String,
        columns: [String]
    ) -> String
    
    /// Returns a SQL update statement.
    ///
    /// How to bind data onto the statement before using is determined by the implementation.
    /// `SQLComposer` from `CacheKit` returns a SQL that asks you to provide all values to
    /// set before the value of the key, e.g., "update table set size = ?, value = ? where key = ?".
    ///
    /// - Parameters:
    ///     - tableName: The table you are updating.
    ///     - columnsToSet: Columns of the records that you want to update.
    ///     - id: Name of the column to find the record.
    func update(
        from tableName: String,
        set columnsToSet: [String],
        by id: String,
        amount: Int
    ) -> String
    
    /// Returns a SQL deletion statement.
    func delete(
        from tableName: String,
        by column: String,
        amount: Int
    ) -> String
}
