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


class ConcurrentBox<Content> {

    let condition = NSCondition()
    var value: Content? = nil

    func put(_ value: Content) {
        condition.withLock {
            while self.value != nil {
                condition.wait()
            }
            self.value = value
            condition.broadcast()
        }
    }

    func take() throws -> Content {
        guard let value = tryTake(until: .distantFuture) else {
            // TODO: Interrupted?
            throw InContextError.unknown
        }
        return value
    }

    func tryTake(until date: Date) -> Content? {
        condition.withLock {
            while self.value == nil {
                let signalled = condition.wait(until: date)
                guard signalled else {
                    return nil
                }
            }
            let value = self.value
            self.value = nil
            condition.broadcast()
            return value
        }
    }

}



//extension Task {

    func globalAwaitResult<Success, Failure>(_ task: Task<Success, Failure>) throws -> Success {
        let box = ConcurrentBox<Result<Success, Failure>>()
        Task {
            let result = await task.result
            box.put(result)
        }
        let result = try box.take()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
//
//}

extension Task {

    func awaitResult() throws -> Success {
        return try globalAwaitResult(self)
    }

}

struct DocumentContext: EvaluationContext, DynamicMemberLookup {

    let store: Store
    let document: Document

//    "title": document.metadata["title"],
//    "content": "WELL THIS SUCKS",
//    "html": html,
//    "date": document.date,
//    "query": { (name: String) -> [[String: Any]] in
//        return [[
//            "date": Date(),
//            "title": "Balls",
//            "url": URL(string: "https://www.google.com")!
//        ]]
//    }

    func documents() throws -> [DocumentContext] {
        let task = Task {
            return try await store
                .documents()
                .map { DocumentContext(store: store, document: $0) }
        }
        return try task.awaitResult()
    }

    func evaluate(call: BoundFunctionCall) throws -> Any? {
        if let _ = try call.argument("query", arg1: "name", type1: String.self) {
            let task = Task {
                return try await store.documents()
                    .map { DocumentContext(store: store, document: $0) }
            }
            return try task.awaitResult()
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
        }
        return document.metadata[member]
    }

}


// TODO: I could support initializing sets to make it easier to generate tags efficiently.
// TODO: I should throw away set operation values with a result of '_'
