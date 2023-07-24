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

}

extension Dictionary {

    @inlinable public func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }

}


public indirect enum Resultable: Equatable, Hashable, CustomStringConvertible {

    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case array(Array<Resultable>)
    case executable(Executable)
    case dictionary(Dictionary<Resultable, Resultable>)

    func eval(_ context: EvaluationContext) throws -> Any? {
        switch self {
        case .int(let int):
            return int
        case .double(let double):
            return double
        case .string(let string):
            return string
        case .bool(let bool):
            return bool
        case .executable(let executable):
            return try executable.eval(context)
        case .array(let array):
            return try array.map { item in
                try item.eval(context)
            }
        case .dictionary(let dictionary):
            return try dictionary
                .map { (key, value) in
                    let key = try key.eval(context)
                    guard let hashableKey = key as? AnyHashable else {
                        throw InContextError.invalidKey(key)
                    }
                    let value = try value.eval(context)
                    return (hashableKey, value)
                }
                .reduce(into: [AnyHashable: Any]()) { $0[$1.0] = $1.1 }
        }
    }

    public var description: String {
        switch self {
        case .int(let int):
            return int.formatted()
        case .double(let double):
            return double.formatted()
        case .string(let string):
            return string
        case .bool(let bool):
            return bool ? "true" : "false"
        case .array(let array):
            return array.description
        case .executable(let executable):
            return executable.description
        case .dictionary(let dictionary):
            return dictionary.description
        }
    }

}
