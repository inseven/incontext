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

struct BoundFunctionCall {

    let context: EvaluationContext  // TODO: Perhaps this should always be the global context?
    let call: FunctionCall

    // Move the operations onto here.

    var signature: String {
        let arguments = call.arguments
            .map { $0.name + ":" }
            .joined()
        return "\(call.name)(\(arguments))"
    }

    func void(_ name: String) -> Bool {
        return call.name == name && call.arguments.isEmpty
    }

    // TODO: Consider separating this out as a match and an evaultate to make it easier to implement?
    // TODO: There should be a mechanism for checking the name.
    func argument<T>(_ name: String, arg1: String, type1: T.Type) throws -> (String, T)? {
        guard call.name == name,
              call.arguments.count == 1,
              call.arguments[0].name == arg1,
              let val1 = try call.arguments[0].result.eval(context) as? T
        else {
            return nil
        }
        return (arg1, val1)
    }

    func arguments<T, K>(_ name: String,
                      arg1: String, type1: T.Type,
                      arg2: String, type2: K.Type) throws -> (String, T, String, K)? {
        guard call.name == name,
              call.arguments.count == 2,
              call.arguments[0].name == arg1,
              call.arguments[1].name == arg2,
              let val1 = try call.arguments[0].result.eval(context) as? T,
              let val2 = try call.arguments[1].result.eval(context) as? K
        else {
            return nil
        }
        return (arg1, val1, arg2, val2)
    }

}
