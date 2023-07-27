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

protocol Queryable {

    func documents(query: QueryDescription) throws -> [Document]

}

class QueryTracker: Queryable {

    let store: Queryable
    var queries: [QueryStatus] = []

    init(store: Queryable) {
        self.store = store
    }

    func documents(query: QueryDescription) throws -> [Document] {
        let documents = try store.documents(query: query)
        queries.append(QueryStatus(query: query,
                                   contentModificationDates: documents.map({ $0.contentModificationDate })))
        return documents
    }

}

struct DocumentContext: EvaluationContext, DynamicMemberLookup {

    let store: Queryable
    let document: Document

    func documents(query: QueryDescription) throws -> [DocumentContext] {
        return try store.documents(query: query)
            .map { DocumentContext(store: store, document: $0) }
    }

    func evaluate(call: BoundFunctionCall) throws -> Any? {

        if let name = try call.arguments(Method("query").argument("name", type: String.self)) {

            guard let queries = document.metadata["queries"] as? [String: Any],
                  let query = queries[name] else {
                throw InContextError.unknownQuery(name)
            }
            return try documents(query: try QueryDescription(definition: query))

        } else if let _ = try call.arguments(Method("children")) {

            return try documents(query: QueryDescription(parent: document.url))

        } else if let _ = try call.arguments(Method("parent")) {

            return try documents(query: QueryDescription(url: document.parent))

        }

        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        guard let value = self[dynamicMember: name] else {
            throw InContextError.unknownSymbol(name)
        }
        return value
    }

    // TODO: Errors if values don't exist?
    // TODO: Support auto-executing callables in a single dispatch model.
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
