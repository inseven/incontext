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

// Responsible for the in-memory cache of template file contents, modification dates. Provides relative-path lookup for
// template contents.
class TemplateCache {

    struct Details {
        let url: URL
        let language: TemplateLanguage
        let contentModificationDate: Date
        let contents: String
    }

    private let rootURL: URL
    private let templates: [TemplateIdentifier: Details]

    static func templates(rootURL: URL, language: TemplateLanguage) async throws -> [TemplateIdentifier: Details] {
        precondition(rootURL.hasDirectoryPath)
        let fileManager = FileManager.default
        let languageRootURL = rootURL.appendingPathComponent(language.rawValue, isDirectory: true)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(at: languageRootURL, isDirectory: &isDirectory) else {
            print("Skipping loading '\(language)' templates...")
            return [:]
        }
        guard isDirectory.boolValue else {
            throw InContextError.internalInconsistency("Failed to load templates for '\(language)' (incorrect directory structure).")
        }

        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .contentModificationDateKey])
        let directoryEnumerator = fileManager.enumerator(at: languageRootURL,
                                                         includingPropertiesForKeys: Array(resourceKeys),
                                                         options: [.skipsHiddenFiles, .producesRelativePathURLs])!
        return try await withThrowingTaskGroup(of: Details.self) { group in
            for case let fileURL as URL in directoryEnumerator {

                let isDirectory = try fileURL
                    .resourceValues(forKeys: [.isDirectoryKey])
                    .isDirectory!
                let contentModificationDate = try fileURL
                    .resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate!

                guard !isDirectory else {
                    continue
                }

                group.addTask {
                    let contents = try String(contentsOf: fileURL, encoding: .utf8)
                    let details = Details(url: fileURL,
                                          language: .stencil,
                                          contentModificationDate: contentModificationDate,
                                          contents: contents)
                    return details
                }
            }

            var templates: [TemplateIdentifier: Details] = [:]
            for try await details in group {
                templates[TemplateIdentifier(language, details.url.relativePath)] = details
            }

            return templates
        }
    }

    init(rootURL: URL) async throws {
        self.rootURL = rootURL
        self.templates = try await TemplateLanguage.allCases
            .asyncReduce(into: [TemplateIdentifier: Details]()) { partialResult, language in
                for (identifier, details) in try await Self.templates(rootURL: rootURL, language: language) {
                    partialResult[identifier] = details
                }
        }
    }

    func details(for identifier: TemplateIdentifier) -> Details? {
        return self.templates[identifier]
    }

    func modificationDate(for identifier: TemplateIdentifier) -> Date? {
        return self.templates[identifier]?.contentModificationDate
    }

}
