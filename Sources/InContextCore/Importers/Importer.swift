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

struct ImporterResult {

    let document: Document?
    let assets: [Asset]

    init(document: Document? = nil, assets: [Asset] = []) {
        self.document = document
        self.assets = assets
    }

}

protocol ImporterSettings: Hashable, Fingerprintable {

}

protocol Importer {

    associatedtype Settings: ImporterSettings

    var identifier: String { get }
    var version: Int { get }

    func settings(for configuration: [String: Any]) throws -> Settings
    func process(file: File,
                 settings: Settings,
                 outputURL: URL) async throws -> ImporterResult

}

extension Importer {

    func handler(when: String, then: String, args: [String: Any]) throws -> AnyHandler {
        // Double-check that the type is correct.
        guard then == self.identifier else {
            throw InContextError.internalInconsistency("Unexpected type for handler settings.")
        }
        let handler = try Handler(when: when, importer: self, settings: try self.settings(for: args))
        return AnyHandler(handler)
    }

}
