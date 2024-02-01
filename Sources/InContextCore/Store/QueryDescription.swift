// MIT License
//
// Copyright (c) 2016-2024 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

import SQLite

struct QueryDescription: Codable, Hashable {

    enum Sort: String, Codable {
        case ascending
        case descending

        static prefix func !(sort: Sort) -> Sort {
            switch sort {
            case .ascending:
                return .descending
            case .descending:
                return .ascending
            }
        }
    }

    static let defaultSort: Sort = .ascending

    let includeCategories: [String]?
    let url: String?
    let parent: String?
    let relativeSourcePath: String?
    let tag: String?
    let sort: Sort?
    let limit: Int?
    let minimumDepth: Int?
    let maximumDepth: Int?

    init(includeCategories: [String]? = nil,
         url: String? = nil,
         parent: String? = nil,
         relativeSourcePath: String? = nil,
         tag: String? = nil,
         minimumDepth: Int? = nil,
         maximumDepth: Int? = nil,
         sort: Sort? = nil,
         limit: Int? = nil) {
        self.includeCategories = includeCategories
        self.url = url
        self.parent = parent
        self.relativeSourcePath = relativeSourcePath
        self.tag = tag
        self.minimumDepth = minimumDepth
        self.maximumDepth = maximumDepth
        self.sort = sort
        self.limit = limit
    }

    init(descendantsOf parent: String,
         maximumDepth: Int?,
         sort: QueryDescription.Sort? = nil) {

        let sort = sort ?? QueryDescription.defaultSort

        let absoluteMaximumDepth: Int?
        if let maximumDepth {
            absoluteMaximumDepth = parent.pathDepth + maximumDepth
        } else {
            absoluteMaximumDepth = nil
        }

        self.init(parent: parent, maximumDepth: absoluteMaximumDepth, sort: sort)
    }

    private func expression() -> Expression<Bool> {

        var expressions: [Expression<Bool>] = []

        if let includeCategories {
            let includeExpression = includeCategories.reduce(Expression<Bool>(value: false)) { result, category in
                let expression: Expression<Bool> = Store.Schema.category == category
                return result || expression
            }
            expressions.append(includeExpression)
        }

        if let url {
            expressions.append(Store.Schema.url == url)
        }

        if let parent {
            // If a maximum depth has been defined that is exactly one greater than the parent depth, we can perform an
            // optimised query which exactly matches the parent URL. In the future, we can build a lookup tree structure
            // to improve performance in the generic case should it prove necessary.
            if let maximumDepth, maximumDepth == parent.pathDepth + 1 {
                expressions.append(Store.Schema.parent == parent)
            } else {
                expressions.append(Store.Schema.parent.like("\(parent)%"))
            }
        }

        if let relativeSourcePath {
            expressions.append(Store.Schema.relativeSourcePath == relativeSourcePath)
        }

        if let tag {
            let expression: Expression<Bool> = Expression("EXISTS (SELECT * FROM json_each(json_extract(metadata, '$.tags')) WHERE json_each.value = ?)", [tag])
            expressions.append(expression)
        }

        if let minimumDepth {
            expressions.append(Store.Schema.depth >= minimumDepth)
        }

        if let maximumDepth {
            expressions.append(Store.Schema.depth <= maximumDepth)
        }

        return expressions.reduce(Expression<Bool>(value: true)) { $0 && $1 }
    }

    private func order() -> [Expressible] {
        switch sort ?? Self.defaultSort {
        case .ascending:
            return [Store.Schema.date.asc, Store.Schema.title.asc]
        case .descending:
            return [Store.Schema.date.desc, Store.Schema.title.asc]
        }
    }

    func query() -> Table {
        Store.Schema.documents
            .filter(expression())
            .order(order())
            .limit(limit)
    }

    init(definition query: Any) throws {
        guard let structuredQuery = query as? [String: Any] else {
            throw InContextError.invalidQueryDefinition
        }
        if let include = structuredQuery["include"] {
            guard let include = include as? [String] else {
                throw InContextError.invalidQueryDefinition
            }
            includeCategories = include
        } else {
            includeCategories = nil
        }
        self.parent = try structuredQuery.optionalValue(for: "parent")
        self.url = try structuredQuery.optionalValue(for: "url")
        self.relativeSourcePath = try structuredQuery.optionalValue(for: "relative_source_path")
        self.tag = try structuredQuery.optionalValue(for: "tag")
        self.sort = try structuredQuery.optionalRawRepresentable(for: "sort")
        self.limit = try structuredQuery.optionalValue(for: "limit")
        self.minimumDepth = try structuredQuery.optionalValue(for: "minimumDepth")
        self.maximumDepth = try structuredQuery.optionalValue(for: "maximumDepth")
    }

}
