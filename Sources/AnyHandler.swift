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

struct AnyHandler {

    let _fingerprint: () throws -> String
    let _identifier: () -> String
    let _process: (Site, File) async throws -> ImporterResult
    let _matches: (String) throws -> Bool

    func fingerprint() throws -> String {
        return try _fingerprint()
    }

    var identifier: String {
        return _identifier()
    }

    init<T: Importer>(_ handler: Handler<T>) {
        _fingerprint = {
            return try handler.fingerprint()
        }
        _identifier = {
            return handler.identifier
        }
        _process = { site, file in
            return try await handler.process(site: site, file: file)
        }
        _matches = { path in
            return try handler.matches(relativePath: path)
        }
    }

    func matches(relativePath: String) throws -> Bool {
        return try _matches(relativePath)
    }

    func process(site: Site, file: File) async throws -> ImporterResult {
        return try await _process(site, file)
    }

}
