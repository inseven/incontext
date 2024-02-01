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

public class ActionRunner {

    let site: Site
    let action: Site.Action
    let tracker: Tracker

    public init(site: Site, action: Site.Action, tracker: Tracker) {
        self.site = site
        self.action = action
        self.tracker = tracker
    }

    static func run(site: Site, action: Site.Action, logger: Logger) throws {
        logger.debug(action.run.trimmingCharacters(in: .whitespacesAndNewlines))

        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.currentDirectoryURL = site.rootURL
        process.launchPath = "/bin/bash"
        process.arguments = []
        process.standardInput = input
        process.standardOutput = output
        process.launch()

        let outputReader = Task {
            guard let data = try output.fileHandleForReading.readToEnd(),
                  let result = String(data: data, encoding: .utf8)
            else {
                throw InContextError.internalInconsistency("Failed to read data!")
            }
            for line in result.split(separator: /\n+/) {
                guard !line.isEmpty else {
                    continue
                }
                logger.info(String(line))
            }
        }

        guard let command = action.run.data(using: .utf8) else {
            throw InContextError.internalInconsistency("Failed to encode action script as input.")
        }

        try input.fileHandleForWriting.write(contentsOf: command)
        try input.fileHandleForWriting.close()

        process.waitUntilExit()
        try outputReader.awaitResult()

        guard process.terminationStatus == 0 else {
            throw InContextError.internalInconsistency("Failed with exit code \(process.terminationStatus).")
        }
    }

    public func run() {
        do {
            try tracker.withSession(type: .action, name: action.name) { session in
                try session.withTask("Running action '\(action.name)'...") { task in
                    try Self.run(site: site, action: action, logger: task)
                }

            }
        } catch {
            print("Task failed with error \(error).")
        }
    }

}
