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

import ArgumentParser
import InContextCore

struct Options: ParsableArguments {

    @Option(help: "path to the root of the site",
            completion: .file(),
            transform: URL.init(fileURLWithPath:))
    var site: URL?

    @Flag(help: "serialize import")
    var serializeImport = false

    @Flag(help: "serialize template render")
    var serializeRender = false

    @Flag(help: "watch for changes to the content directory")
    var watch = false

    func resolveSite() throws -> Site {
        if let site {
            return try Site(rootURL: site)
        }
        let fileManager = FileManager.default
        for directoryURL in ParentIterator(fileManager.currentDirectoryURL) {
            let settingsURL = directoryURL.appendingPathComponent("site.yaml")
            if fileManager.fileExists(at: settingsURL) {
                return try Site(rootURL: directoryURL)
            }
        }
        throw InContextError.internalInconsistency("Unable to detect site in current directory tree.")
    }

}
