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

struct QueryDescription: Encodable {

    let includeCategories: [String]?
    let url: String?
    let parent: String?

    init(includeCategories: [String]? = nil, url: String? = nil, parent: String? = nil) {
        self.includeCategories = includeCategories
        self.url = url
        self.parent = parent
    }

    func expression() -> Expression<Bool> {

        var expressions: [Expression<Bool>] = []

        if let includeCategories {
            let includeExpression = includeCategories.reduce(Expression<Bool>(value: false)) { result, category in
                let expression: Expression<Bool> = Store.Schema.type == category
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

        return expressions.reduce(Expression<Bool>(value: true)) { $0 && $1 }
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
        if let parent = structuredQuery["parent"] {
            guard let parent = parent as? String else {
                throw InContextError.invalidQueryDefinition
            }
            self.parent = parent
        } else {
            self.parent = nil
        }
        self.url = try structuredQuery.optionalValue(for: "parent") 
    }

}
