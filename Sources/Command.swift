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

import ArgumentParser

@main
struct Command: AsyncParsableCommand {

    static var configuration = CommandConfiguration(commandName: "incontext")

    @Flag(help: "run template renders concurrently")
    var concurrentRenders = false

    @Option(help: "path to the root of the site",
            completion: .file(),
            transform: URL.init(fileURLWithPath:))
    var site: URL?

    func detectSiteURL() throws -> URL {
        let fileManager = FileManager.default
        for directoryURL in ParentIterator(fileManager.currentDirectoryURL) {
            let settingsURL = directoryURL.appendingPathComponent("site.yaml")
            if fileManager.fileExists(at: settingsURL) {
                return directoryURL
            }
        }
        throw InContextError.internalInconsistency("Unable to detect site in current directory tree.")
    }

    mutating func run() async throws {
        let siteURL = try (site ?? (try detectSiteURL()))
        print("Using site at '\(siteURL.path)'...")
        let site = try Site(rootURL: siteURL)
        let ic = try await Builder(site: site, concurrentRenders: concurrentRenders)
        try await ic.build()
    }

}
