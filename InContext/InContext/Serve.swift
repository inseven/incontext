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
import InContextCore
import Hummingbird
import HummingbirdFoundation

struct Serve: AsyncParsableCommand {

    static var configuration = CommandConfiguration(commandName: "serve",
                                                    abstract: "run a local web server for development")

    @OptionGroup var options: Options

    mutating func run() async throws {

        // Start the server.
        let app = HBApplication(configuration: .init(address: .hostname("127.0.0.1", port: 8000)))
        let site = try options.resolveSite()
        let middleware = HBFileMiddleware(site.filesURL.path, searchForIndexHtml: true, application: app)
        app.middleware.add(middleware)
        try app.start()

        guard options.watch else {
            // If we're not watching for builds, we need to wait on the web server.
            app.wait()
            return
        }

        let ic = try await Builder(site: site,
                                   serializeImport: options.serializeImport,
                                   serializeRender: options.serializeRender)
        try await ic.build(watch: options.watch)
    }

}
