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

public enum CompletionState {

    case completed
    case skipped

}

public protocol Finishable {

    func finish(result: Result<CompletionState, Error>)

}

extension Finishable {

    func success(_ state: CompletionState = .completed) {
        finish(result: .success(state))
    }

    func failure(_ error: Error) {
        finish(result: .failure(error))
    }

    func run<T>(_ task: () async throws -> T) async rethrows -> T {
        do {
            let result = try await task()
            success()
            return result
        } catch {
            failure(error)
            throw error
        }
    }

    func run<T>(_ task: () throws -> T) rethrows -> T {
        do {
            let result = try task()
            success()
            return result
        } catch {
            failure(error)
            throw error
        }
    }

}
