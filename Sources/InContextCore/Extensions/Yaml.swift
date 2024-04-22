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

import Yaml

extension Yaml {

    static let dateParser = DateParser()

    func dictionary() throws -> [AnyHashable: Any] {
        guard let dictionary = native() as? [AnyHashable: Any] else {
            throw InContextError.invalidMetadata
        }
        return dictionary
    }

    func native() -> Any? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return Self.dateParser.date(from: value) ?? value
        case .array(let values):
            return values.compactMap {
                $0.native()
            }
        case .dictionary(let values):
            let nativeValues: [(AnyHashable, Any)] = values.compactMap { (key, value) in
                guard let key = key.native() as? AnyHashable,
                      let value = value.native() else {
                    return nil
                }
                return (key, value)
            }
            return nativeValues.reduce(into: [AnyHashable:Any]()) { partialResult, item in
                partialResult[item.0] = item.1
            }

        }
    }

}
