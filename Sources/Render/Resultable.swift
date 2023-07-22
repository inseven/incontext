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

public indirect enum Resultable: Equatable, Hashable {

    case int(Int)
    case double(Double)
    case string(String)
    case array(Array<Resultable>)
    case executable(Executable)
    case dictionary(Dictionary<Resultable, Resultable>)

    func eval(_ context: EvaluationContext) throws -> Any? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
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

}
