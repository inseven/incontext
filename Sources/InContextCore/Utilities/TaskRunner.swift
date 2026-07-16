// MIT License
//
// Copyright (c) 2016-2026 Jason Morley
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

struct Tasks<T> {

    fileprivate var tasks: [() async throws -> T?] = []

    mutating func add(task: @escaping () async throws -> T?) {
        tasks.append(task)
    }
}

func withTaskRunner<T>(of: T.Type, maximumConcurrentTasks: Int, body: (inout Tasks<T>) async throws -> Void) async throws -> [T] {

    var tasks = Tasks<T>()
    try await body(&tasks)

    return try await withThrowingTaskGroup(of: Optional<T>.self) { group in
        var iterator = tasks.tasks.makeIterator()

        // Prime the runner with minimumConcurrentTasks tasks.
        for _ in 0..<maximumConcurrentTasks {
            guard let task = iterator.next() else {
                break
            }
            group.addTask { try await task() }
        }

        // Pull completed tasks from the group, adding a new task each time until we run out.
        // This guarantees that we see failures as soon as they happen.
        var results: [T] = []
        while let result = try await group.next() {
            if let result {
                results.append(result)
            }
            if let task = iterator.next() {
                group.addTask { try await task() }
            }
        }
        return results
    }

}
