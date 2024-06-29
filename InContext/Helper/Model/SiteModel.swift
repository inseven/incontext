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
import SwiftUI

import InContextCore

class SiteModel: ObservableObject, Identifiable {

    var id: URL { return rootURL }

    let rootURL: URL
    
    private let site: Site
    private let server: Server
    private var task: Task<(), Never>? = nil

    let tracker = HelperTracker()

    var url: URL {
        return server.url
    }

    var title: String {
        return site.title
    }

    init(rootURL: URL) {
        self.rootURL = rootURL
        // TODO: Guard the configuration loading.
        // TODO: The configuration should likely be pushed into the server as we need to watch for changes
        self.site = try! Site(rootURL: rootURL)
        self.server = Server(site: site, tracker: tracker)
    }

    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        self.task = Task(priority: .medium) {
            do {
                try await server.start(watch: true)
            } catch {
                // TODO: This shouldn't happen.
                print("FAILED WITH ERROR!! \(error)")
            }
        }
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        self.task?.cancel()
        self.task = nil
    }

    @MainActor func open() {
        dispatchPrecondition(condition: .onQueue(.main))
        NSWorkspace.shared.open(site.url)
    }

    @MainActor func preview() {
        dispatchPrecondition(condition: .onQueue(.main))
        NSWorkspace.shared.open(url)
    }

}
