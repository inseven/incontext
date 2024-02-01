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

struct Tasks<T> {

    fileprivate var tasks: [() async throws -> T?] = []

    mutating func add(task: @escaping () async throws -> T?) {
        tasks.append(task)
    }
}

func withTaskRunner<T>(of: T.Type, concurrent: Bool, body: (inout Tasks<T>) async throws -> Void) async throws -> [T] {

    var tasks = Tasks<T>()
    try await body(&tasks)

    guard concurrent else {

        var results = [T]()
        for task in tasks.tasks {
            guard let result = try await task() else {
                continue
            }
            results.append(result)
        }

        return results
    }

    return try await withThrowingTaskGroup(of: Optional<T>.self) { group in

        for task in tasks.tasks {
            group.addTask {
                return try await task()
            }
        }

        var results: [T] = []
        for try await result in group {
            guard let result else {
                continue
            }
            results.append(result)
        }
        return results
    }

}
