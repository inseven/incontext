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

extension Array {
    
    @inlinable func asyncFilter(_ isIncluded: @escaping (Element) async throws -> Bool) async rethrows -> [Element] {
        var result = [Element]()
        for element in self {
            if try await isIncluded(element) {
                result.append(element)
            }
        }
        return result
    }

    @inlinable public func asyncCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            guard let newElement = try await transform(element) else {
                continue
            }
            result.append(newElement)
        }
        return result
    }

    @inlinable public func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }

    @inlinable public func asyncReduce<Result>(_ initialResult: Result,
                                               _ nextPartialResult: @escaping (Result, Element) async throws -> Result) async rethrows -> Result {
        var result = initialResult
        for element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }

    @inlinable public func asyncReduce<Result>(into initialResult: Result,
                                               _ updateAccumulatingResult: (_ partialResult: inout Result, Self.Element) async throws -> ()) async rethrows -> Result {
        var result: Result = initialResult
        for element in self {
            try await updateAccumulatingResult(&result, element)
        }
        return result
    }

}

extension Array: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        let items: [any Fingerprintable] = try cast(self)
        for item in items {
            try fingerprint.update(item)
        }
    }

}
