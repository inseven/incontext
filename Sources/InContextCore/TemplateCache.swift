// MIT License
//
// Copyright (c) 2023 Jason Morley
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

// Responsible for the in-memory cache of template file contents, modification dates. Provides relative-path lookup for
// template contents.
class TemplateCache {

    private let rootURL: URL
    private let cache = Cache<TemplateIdentifier, TemplateDetails>()


    init(rootURL: URL) async throws {
        precondition(rootURL.hasDirectoryPath)
        self.rootURL = rootURL
    }

    func details(for identifier: TemplateIdentifier) throws -> TemplateDetails? {

        // Check the cache.
        if let details = cache[identifier] {
            return details
        }

        // Load the template.
        let fileManager = FileManager.default
        let templateURL = URL(filePath: identifier.name, relativeTo: rootURL)
        guard fileManager.fileExists(at: templateURL) else {
            throw InContextError.unknownTemplate(identifier.name)
        }

        // N.B. Since we can't read the mtime and contents atomically, we read the mtime first to ensure it only ever
        // lags behind the contents and, if they're out of sync, we'll over render, not under render. This means we may
        // miss changes during a render, but our cached mtimes will be such that they will be correctly picked up on a
        // subsequent render.

        let modificationDate = try FileManager.default.modificationDateOfItem(at: templateURL)
        let contents = try String(contentsOf: templateURL, encoding: .utf8)
        let details = TemplateDetails(url: templateURL,
                                      modificationDate: modificationDate,
                                      contents: contents)

        // Cache the template.
        cache[identifier] = details

        return details
    }

    func modificationDate(for identifier: TemplateIdentifier) throws -> Date? {
        return try details(for: identifier)?.modificationDate
    }

    func clear() {
        cache.removeAll()
    }

}
