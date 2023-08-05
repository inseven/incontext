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
import Hummingbird
import HummingbirdFoundation

@main
struct Command: AsyncParsableCommand {

    static var configuration = CommandConfiguration(commandName: "incontext",
                                                    subcommands: [
                                                        Build.self,
                                                        Clean.self,
                                                        Serve.self,
                                                    ])

}

struct Options: ParsableArguments {

    @Option(help: "path to the root of the site",
            completion: .file(),
            transform: URL.init(fileURLWithPath:))
    var site: URL?

    @Flag(help: "run template renders concurrently")
    var concurrentRenders = false

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

extension Command {

    struct Build: AsyncParsableCommand {

        static var configuration = CommandConfiguration(commandName: "build",
                                                        abstract: "build the website")

        @OptionGroup var options: Options

        mutating func run() async throws {
            let site = try options.resolveSite()
            let ic = try await Builder(site: site, concurrentRenders: options.concurrentRenders)
            try await ic.build(watch: options.watch)
        }

    }

    struct Serve: AsyncParsableCommand {

        static var configuration = CommandConfiguration(commandName: "serve",
                                                        abstract: "run a local web server for development")

        @OptionGroup var options: Options

        mutating func run() async throws {
            let app = HBApplication(configuration: .init(address: .hostname("127.0.0.1", port: 8000)))
            let site = try options.resolveSite()
            let middleware = HBFileMiddleware(site.filesURL.path, searchForIndexHtml: true, application: app)
            app.middleware.add(middleware)
            try app.start()
            app.wait()
        }

    }

    struct Clean: AsyncParsableCommand {

        @OptionGroup var options: Options

        static var configuration = CommandConfiguration(commandName: "clean",
                                                        abstract: "remove the build directory")

        mutating func run() async throws {
            let site = try options.resolveSite()
            try FileManager.default.removeItem(at: site.buildURL)
        }

    }

}
