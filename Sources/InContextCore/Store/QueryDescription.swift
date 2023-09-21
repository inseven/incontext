// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
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

struct QueryDescription: Codable, Hashable, Equatable, Fingerprintable {

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case includeCategories = "include"
        case url = "url"
        case parent = "parent"
        case relativeSourcePath = "relative_source_path"
        case tag = "tag"
        case sort = "sort"
        case limit = "limit"
    }

    // TODO: Move this out?
    func combine(into fingerprint: inout Fingerprint) throws {
        if let includeCategories {
            try fingerprint.update(includeCategories)
        }
        if let url {
            try fingerprint.update(url)
        }
        if let parent {
            try fingerprint.update(parent)
        }
        if let relativeSourcePath {
            try fingerprint.update(relativeSourcePath)
        }
        if let tag {
            try fingerprint.update(tag)
        }
        if let sort {
            try fingerprint.update(sort.rawValue)
        }
        if let limit {
            try fingerprint.update(limit)
        }
    }

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

    init(includeCategories: [String]? = nil,
         url: String? = nil,
         parent: String? = nil,
         relativeSourcePath: String? = nil,
         tag: String? = nil,
         sort: Sort? = nil,
         limit: Int? = nil) {
        self.includeCategories = includeCategories
        self.url = url
        self.parent = parent
        self.relativeSourcePath = relativeSourcePath
        self.tag = tag
        self.sort = sort
        self.limit = limit
    }

    // TODO: Maybe this isn't necessary anymore?
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
    }

    func encode(to encoder: Encoder) throws {
        // TODO: Update the coding key values.
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.includeCategories, forKey: .includeCategories)
        try container.encodeIfPresent(self.url, forKey: .url)
        try container.encodeIfPresent(self.parent, forKey: .parent)
        try container.encodeIfPresent(self.relativeSourcePath, forKey: .relativeSourcePath)
        try container.encodeIfPresent(self.tag, forKey: .tag)
        try container.encodeIfPresent(self.sort, forKey: .sort)
        try container.encodeIfPresent(self.limit, forKey: .limit)
    }

    // TODO: Decode?

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
            expressions.append(Store.Schema.parent == parent)
        }

        if let relativeSourcePath {
            expressions.append(Store.Schema.relativeSourcePath == relativeSourcePath)
        }

        if let tag {
            let expression: Expression<Bool> = Expression("EXISTS (SELECT * FROM json_each(json_extract(metadata, '$.tags')) WHERE json_each.value = ?)", [tag])
            expressions.append(expression)
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

}
