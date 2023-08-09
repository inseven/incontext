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
import UniformTypeIdentifiers

import Yaml

struct Site {

    let rootURL: URL
    let contentURL: URL
    let templatesURL: URL
    let buildURL: URL
    let storeURL: URL
    let filesURL: URL

    let settings: [AnyHashable: Any]

    let handlers: [AnyHandler]

    init(rootURL: URL) throws {
        self.rootURL = rootURL
        self.contentURL = rootURL.appendingPathComponent("content", isDirectory: true)
        self.templatesURL = rootURL.appendingPathComponent("templates", isDirectory: true)
        self.buildURL = rootURL.appendingPathComponent("build-swift", isDirectory: true)
        self.storeURL = buildURL.appendingPathComponent("store.sqlite")
        self.filesURL = buildURL.appendingPathComponent("files", isDirectory: true)

        let settingsURL = rootURL.appendingPathComponent("site.yaml")
        let settingsData = try Data(contentsOf: settingsURL)
        guard let settingsString = String(data: settingsData, encoding: .utf8) else {
            throw InContextError.encodingError
        }
        self.settings = try (try Yaml.load(settingsString)).dictionary()

        guard let buildSteps = settings["build_steps"] as? [[String: Any]],
              let processFiles = buildSteps.first,
              processFiles["task"] as? String == "process_files",
              let args = processFiles["args"] as? [String: Any],
              let handlers = args["handlers"] as? [[String: Any]]
        else {
            throw InContextError.corruptSettings
        }

        let importers = ([
            CopyImporter(),
            IgnoreImporter(),
            ImageImporter(),
            MarkdownImporter(),
            VideoImporter(),
        ] as [any Importer]).reduce(into: [:]) { $0[$1.identifier] = $1 }

        let actualHandlers = try handlers.map { handler in
            guard let then = handler["then"] as? String else {
                throw InContextError.corruptSettings
            }
            guard let importer = importers[then] else {
                throw InContextError.unknownImporter(then)
            }
            return try importer.handler(settings: handler)
        }
        self.handlers = actualHandlers
    }

    func handler(for url: URL) throws -> AnyHandler? {
        for handler in handlers {
            guard try handler.matches(relativePath: url.relativePath) else {
                continue
            }
            return handler
        }
        return nil
    }

    func outputURL(relativePath: String) -> URL {
        return URL(filePath: relativePath, relativeTo: filesURL)
    }

}
