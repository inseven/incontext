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

import PlatformSupport

class ConcurrentBox<Content> {

    let condition = NSCondition()
    var value: Content? = nil

    func tryPut(_ value: Content) -> Bool {
        condition.withLock {
            guard self.value == nil else {
                return false
            }
            self.value = value
            condition.broadcast()
            return true
        }
    }

    func put(_ value: Content) {
        condition.withLock {
            while self.value != nil {
                condition.wait()
            }
            self.value = value
            condition.broadcast()
        }
    }

    func take() throws -> Content {
        guard let value = tryTake(until: .distantFuture) else {
            throw InContextError.interrupted
        }
        return value
    }

    func tryTake(until date: Date) -> Content? {
        condition.withLock {
            while self.value == nil {
                let signalled = condition.wait(until: date)
                guard signalled else {
                    return nil
                }
            }
            let value = self.value
            self.value = nil
            condition.broadcast()
            return value
        }
    }

}
