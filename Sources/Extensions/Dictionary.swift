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

extension Dictionary {

    func value<T>(for key: Key, default defaultValue: T) throws -> T {
        guard let value = self[key] else {
            return defaultValue
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(expected: T.Type.self, received: value)
        }
        return value
    }

    func optionalValue<T>(for path: [Key]) throws -> T? {
        guard let key = path.first else {
            throw InContextError.internalInconsistency("Failed to get the first key for path \(path).")
        }
        if path.count == 1 {
            return try optionalValue(for: key)
        }
        guard let dictionary: [Key: Any] = try optionalValue(for: key) else {
            return nil
        }
        return try dictionary.optionalValue(for: Array(path[1...]))
    }

    func optionalValue<T>(for key: Key) throws -> T? {
        guard let value = self[key] else {
            return nil
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(expected: T.Type.self, received: value)
        }
        return value
    }

    func requiredValue<T>(for key: Key) throws -> T {
        guard let value = self[key] else {
            throw InContextError.missingKey(key)
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(expected: T.Type.self, received: value)
        }
        return value
    }

    func requiredRawRepresentable<T: RawRepresentable>(for key: Key) throws -> T {
        let rawValue: T.RawValue = try requiredValue(for: key)
        guard let value = T(rawValue: rawValue) else {
            throw InContextError.incorrectType(expected: T.Type.self, received: rawValue)
        }
        return value
    }

    func optionalRawRepresentable<T: RawRepresentable>(for key: Key) throws -> T? {
        guard let rawValue: T.RawValue = try optionalValue(for: key) else {
            return nil
        }
        guard let value = T(rawValue: rawValue) else {
            throw InContextError.incorrectType(expected: T.Type.self, received: rawValue)
        }
        return value
    }

    func optionalRawRepresentable<T: RawRepresentable>(for path: [Key]) throws -> T? {
        guard let key = path.first else {
            throw InContextError.internalInconsistency("Failed to get the first key for path \(path).")
        }
        if path.count == 1 {
            return try optionalRawRepresentable(for: key)
        }
        guard let dictionary: [Key: Any] = try optionalValue(for: key) else {
            return nil
        }
        return try dictionary.optionalRawRepresentable(for: Array(path[1...]))
    }

    @inlinable public func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }

}

extension Dictionary: EvaluationContext where Key == AnyHashable, Value == Any {

    func lookup(_ name: String) throws -> Any? {
        return self[name]
    }

}
