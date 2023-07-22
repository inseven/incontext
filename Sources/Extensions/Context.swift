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

import Stencil

//extension Dictionary: EvaluationContext {
//
//    func evaluate(call: BoundFunctionCall) throws -> Any? {
//
//    }
//
//    func lookup(_ name: String) throws -> Any? {
//        return self[name]
//    }
//
//}

extension Context: EvaluationContext {

    func evaluate(call: BoundFunctionCall) throws -> Any? {
        // TODO: This is where we'd see if we had a top-level member that was (somehow) callable.
        // TODO: Perhaps a Protocol on a class at this level?

        // TODO: It would be much better if this was injected into the environment from outside. But hey it works right now.
        if call.void("generate_uuid") {
            return UUID().uuidString
        }

        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: This should throw if the variable doesn't exist in the context, but I'm not sure how to know that right now.
        // TODO: This should perhaps also support the other lookup mechanisms?
        return self[name]
    }

}
