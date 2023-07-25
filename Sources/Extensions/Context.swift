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

extension Context: EvaluationContext {

    func evaluate(call: BoundFunctionCall) throws -> Any? {
        // TODO: This is where we'd see if we had a top-level member that was (somehow) callable.
        // TODO: Perhaps a Protocol on a class at this level?

        // TODO: Consider whether these should really be injected in the top-level in this way.
        if let arguments = try call.arguments(Method("add").argument("lhs", type: Int.self).argument("rhs", type: Int.self)) {

            // add(lhs: Int, rhs: Int) -> Int
            return arguments.0 + arguments.1

        } else if let arguments = try call.arguments(Method("add").argument("lhs", type: Double.self).argument("rhs", type: Int.self)) {

            // add(lhs: Double, rhs: Int) -> Double
            return arguments.0 + Double(arguments.1)

        } else if let arguments = try call.arguments(Method("add").argument("lhs", type: Int.self).argument("rhs", type: Double.self)) {

            // add(lhs: Int, rhs: Double) -> Double
            return Double(arguments.0) + arguments.1

        } else if let arguments = try call.arguments(Method("add").argument("lhs", type: Double.self).argument("rhs", type: Double.self)) {

            // add(lhs: Double, rhs: Double) -> Double
            return arguments.0 + arguments.1

        } else if let arguments = try call.arguments(Method("div").argument("lhs", type: Int.self).argument("rhs", type: Int.self)) {

            // div(lhs: Int, rhs: Int) -> Int
            return arguments.0 / arguments.1

        } else if let arguments = try call.arguments(Method("div").argument("lhs", type: Double.self).argument("rhs", type: Int.self)) {

            // div(lhs: Double, rhs: Int) -> Double
            return arguments.0 / Double(arguments.1)

        } else if let arguments = try call.arguments(Method("div").argument("lhs", type: Int.self).argument("rhs", type: Double.self)) {

            // div(lhs: Int, rhs: Double) -> Double
            return Double(arguments.0) / arguments.1

        } else if let arguments = try call.arguments(Method("div").argument("lhs", type: Double.self).argument("rhs", type: Double.self)) {

            // div(lhs: Double, rhs: Double) -> Double
            return arguments.0 / arguments.1

        } else if let arguments = try call.arguments(Method("mul").argument("lhs", type: Int.self).argument("rhs", type: Int.self)) {

            // mul(lhs: Int, rhs: Int) -> Int
            return arguments.0 * arguments.1

        } else if let arguments = try call.arguments(Method("mul").argument("lhs", type: Double.self).argument("rhs", type: Int.self)) {

            // mul(lhs: Double, rhs: Int) -> Double
            return arguments.0 * Double(arguments.1)

        } else if let arguments = try call.arguments(Method("mul").argument("lhs", type: Int.self).argument("rhs", type: Double.self)) {

            // mul(lhs: Int, rhs: Double) -> Double
            return Double(arguments.0) * arguments.1

        } else if let arguments = try call.arguments(Method("mul").argument("lhs", type: Double.self).argument("rhs", type: Double.self)) {

            // mul(lhs: Double, rhs: Double) -> Double
            return arguments.0 * arguments.1

        } else if let callable = self[call.call.name] as? CallableBlock {

            return try callable.evaluate(call: call)

        }
        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: This should throw if the variable doesn't exist in the context, but I'm not sure how to know that right now.
        // TODO: This should perhaps also support the other lookup mechanisms?
        return self[name]
    }

}
