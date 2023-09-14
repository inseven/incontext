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

public class ActionRunner {

    let site: Site
    let action: Site.Action
    let tracker: Tracker

    public init(site: Site, action: Site.Action, tracker: Tracker) {
        self.site = site
        self.action = action
        self.tracker = tracker
    }

    public func run() {

        let session = tracker.new(action.name)
        session.info("Running action '\(action.name)'...")
        session.debug(action.run.trimmingCharacters(in: .whitespacesAndNewlines))

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
                session.error("Failed to read data!")
                return
            }
            for line in result.split(separator: /\n+/) {
                guard !line.isEmpty else {
                    continue
                }
                session.info(String(line))
            }
        }

        guard let command = action.run.data(using: .utf8) else {
            session.error("Failed to encode action script as input.")
            return
        }
        do {
            try input.fileHandleForWriting.write(contentsOf: command)
            try input.fileHandleForWriting.close()
        } catch {
            session.error("Failed to run action with error '\(error)'.")
            return
        }
        process.waitUntilExit()

        do {
            try outputReader.awaitResult()
        } catch {
            session.error("Failed to get output with error \(error).")
            return
        }

        if process.terminationStatus == 0 {
            session.info("Complete.")
        } else {
            session.error("Failed with exit code \(process.terminationStatus).")
        }
    }

}
