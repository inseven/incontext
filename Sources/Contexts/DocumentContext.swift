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

import Stencil

struct DocumentContext: EvaluationContext, DynamicMemberLookup {

    let store: Store
    let document: Document

    func documents() throws -> [DocumentContext] {
        let task = Task {
            return try await store
                .documents()
                .map { DocumentContext(store: store, document: $0) }
        }
        return try task.awaitResult()
    }

    // TODO: Structured parser for the query definition which has nice clean error reporting.
    func evaluate(call: BoundFunctionCall) throws -> Any? {
        if let name = try call.arguments(Method("query").argument("name", type: String.self)) {
            guard let queries = document.metadata["queries"] as? [String: Any],
                  let query = queries[name]
            else {
                print(document.metadata)
                // TODO: Errors should include the document being rendered!
                throw InContextError.unknownQuery(name)
            }
            guard let structuredQuery = query as? [String: Any] else {
                throw InContextError.invalidQueryDefinition(name)
            }
            var includeCategories: [String]? = nil
            if let include = structuredQuery["include"] {
                // TODO: Guard against a tuple of strings?
                guard let include = include as? [String] else {
                    print(type(of: include))
                    throw InContextError.invalidQueryDefinition(name)
                }
                includeCategories = include
            }
            return try store.syncDocuments(includingCategories: includeCategories)
                .map { DocumentContext(store: store, document: $0) }
        }
        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: Ensure we fail with misisng properties?
        return self[dynamicMember: name]
    }

    // TODO: Support Python and Swift naming conventions
    // TODO: Errors if values don't exist?
    subscript(dynamicMember member: String) -> Any? {
        if member == "content" {
            return document.contents
        } else if member == "date" {
            return document.date
        } else if member == "html" {
            return document.contents
        } else if member == "url" {
            return document.url
        }
        return document.metadata[member]
    }

}


// TODO: I could support initializing sets to make it easier to generate tags efficiently.
// TODO: I should throw away set operation values with a result of '_'
