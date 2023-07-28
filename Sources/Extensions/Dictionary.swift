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

// TODO: Conisder whether callables should be anonymous by default and everything before () should be lookups?
// TODO: This could lead to just one method on EvaluationContext; might be nice?

// TODO: Not sure this is actually used at all; I think they all get wrapped by Context in the end anyhow.
extension Dictionary: EvaluationContext where Key == AnyHashable, Value == Any {

    func evaluate(call: BoundFunctionCall) throws -> Any? {
        // We currently handle callable blocks
        guard let callable = self[call.call.name] as? CallableBlock else {
            throw InContextError.unknownFunction(call.signature)
        }
        return try callable.evaluate(call: call)
    }

    func lookup(_ name: String) throws -> Any? {
        return self[name]
    }

}

extension Dictionary {

    func value<T>(for key: Key, default defaultValue: T) throws -> T {
        guard let value = self[key] else {
            return defaultValue
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(key)
        }
        return value
    }

    func optionalValue<T>(for key: Key) throws -> T? {
        guard let value = self[key] else {
            return nil
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(key)
        }
        return value
    }

    func requiredValue<T>(for key: Key) throws -> T {
        guard let value = self[key] else {
            throw InContextError.missingKey(key)
        }
        guard let value = value as? T else {
            throw InContextError.incorrectType(key)  // TODO: Include expects?
        }
        return value
    }

    @inlinable public func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }

}
