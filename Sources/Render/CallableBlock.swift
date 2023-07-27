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

struct CallableBlock: EvaluationContext {

    let evaluate: (ic3.BoundFunctionCall) throws -> Any?

    func evaluate(call: ic3.BoundFunctionCall) throws -> Any? {
        return try evaluate(call)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: Consider whether a void method should be evaulated without explicit '()'
        throw InContextError.unknownSymbol(name)
    }

}

// TODO: Perhaps this should be allowed to be anonymous?
extension CallableBlock {

    init(_ method: ic3.Method, perform: @escaping () throws -> Any?) {
        self.evaluate = { call in
            guard let _ = try call.arguments(method) else {
                throw InContextError.unknownFunction(call.signature)
            }
            return try perform()
        }
    }

    init<T>(_ method: Bind<ic3.Method, Argument<T>>, perform: @escaping (T) -> Any?) {
        self.evaluate = { call in
            guard let argument = try call.arguments(method) else {
                throw InContextError.unknownFunction(call.signature)
            }
            return perform(argument)
        }
    }

    init<Arg1, Arg2>(_ method: Bind<Bind<ic3.Method, Argument<Arg1>>, Argument<Arg2>>, perform: @escaping (Arg1, Arg2) -> Any?) {
        self.evaluate = { call in
            guard let argument = try call.arguments(method) else {
                throw InContextError.unknownFunction(call.signature)
            }
            return perform(argument.0, argument.1)
        }
    }

}
