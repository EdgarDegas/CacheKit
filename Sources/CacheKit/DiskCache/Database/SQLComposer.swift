//
//  SQLComposer.swift
//  CacheKit
//
//  Created by iMoe Nya on 2020/12/30.
//

import Foundation

/// `CacheKit` use this class to compose SQL statements.
///
/// SQL is not a genre of music, strictly.
final public class SQLComposer: SQLComposing {
    public func createTable(
        named tableName: String,
        withColumns columns: [ColumnDefinition]
    ) -> String {
        var indices = [String]()
        let columnDefinitions: String = columns
            .map {
                var statement = "\($0.name) \($0.type)"
                if $0.indexed {
                    indices.append($0.name)
                }
                if $0.primary {
                    statement += " primary key"
                }
                if !$0.nullable {
                    statement += " not null"
                }
                return statement
            }
            .joined(separator: ", ")
        let indexDefinitions: String = indices
            .map {
                "create index if not exists \($0)_idx on \(tableName)(\($0))"
            }
            .joined(separator: "; ")
        return
            "pragma journal_mode = wal; " +
            "pragma synchronous = normal; " +
            "create table if not exists \(tableName) (\(columnDefinitions));"
            + (!indexDefinitions.isEmpty ? " " + indexDefinitions + ";" : "")
    }
    
    public func select(
        from tableName: String,
        by column: String,
        amount: Int
    ) -> String {
        if amount == 1 {
            return "select * from \(tableName) where \(column) = ?;"
        } else {
            return "select * from \(tableName) where \(column) in (\(valuePlaceholder(at: amount)));"
        }
    }
    
    public func selectRecords(
        from tableName: String,
        orderedBy column: String,
        ascending: Bool,
        limitedAt limit: Int?
    ) -> String {
        let sorting = ascending ? "asc" : "desc"
        // limitation itself includes a space
        let limitation = limit != nil ? " limit \(limit!)" : ""
        return "select * from \(tableName) order by \(column) \(sorting)" + limitation + ";"
    }
    
    public func selectCount(from tableName: String) -> String {
        "select count(*) from \(tableName);"
    }
    
    public func selectSum(
        from tableName: String,
        of column: String
    ) -> String {
        "select sum(\(column)) from \(tableName);"
    }
    
    public func insert(
        into tableName: String,
        columns: [String]
    ) -> String {
        let separator = ", "
        let columnsInSQL = columns.joined(separator: separator)
        let valuesPlaceholder =
            (0..<columns.count)
            .map { _ in "?" }
            .joined(separator: separator)
        return "insert or replace into \(tableName) (\(columnsInSQL)) values (\(valuesPlaceholder));"
    }
    
    public func update(
        from tableName: String,
        set columnsToSet: [String],
        by id: String,
        amount: Int
    ) -> String {
        let updateStatement = columnsToSet
            .map { "\($0) = ?" }
            .joined(separator: ", ")
        if amount == 1 {
            return "update \(tableName) set \(updateStatement) where \(id) = ?;"
        } else {
            return "update \(tableName) set \(updateStatement) where \(id) in (\(valuePlaceholder(at: amount)));"
        }
    }
    
    public func delete(
        from tableName: String,
        by column: String,
        amount: Int
    ) -> String {
        if amount == 1 {
            return "delete from \(tableName) where \(column) = ?;"
        } else {
            return "delete from \(tableName) where \(column) in (\(valuePlaceholder(at: amount)));"
        }
    }
}

private extension SQLComposer {
    func valuePlaceholder(at amount: Int) -> String {
        (0..<amount).map { _ in "?" }.joined(separator: ", ")
    }
}
