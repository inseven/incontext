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

// TODO: Could return KeyValuePairs as the generic solution for args though this needs to be typed somehow?

protocol DynamicCallable {

    func perform(_ call: BoundFunctionCall) throws -> Any?

}

// TODO: These could probably be made typesafe up to n arguments.

struct EchoCallable: DynamicCallable {

    // TODO: This needs to check for the method name too!
    // TODO: It would be more elegant to not have to pass in the evaluation context but have that done before?
    func perform(_ call: BoundFunctionCall) throws -> Any? {
        if let argument = try call.argument(name1: "string", type1: String.self) {
            return argument.1.toTitleCase()
        }
        throw InContextError.unknown
    }

}

// TODO: Maybe the method name is nullable to indicate top level?

extension Context: EvaluationContext {

    func evaluate(call: FunctionCall) throws -> Any? {
        // TODO: Look up the function name not the object name.
        guard let instance = self["object"] else {
            // TODO: Throw a better error.
            throw InContextError.unknown
        }
        guard let callable = instance as? DynamicCallable else {
            // TODO: Throw a meaningful error so we understand that this doesn't conform.
            throw InContextError.unknown
        }
        return try callable.perform(BoundFunctionCall(context: self, callable: call))
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: This should throw if the variable doesn't exist in the context, but I'm not sure how to know that right now.
        return self[name]
    }

}

class SetNode: NodeType {

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        return SetNode(token: token, contents: token.contents)
    }

    let token: Token?
    let contents: String

    init(token: Token, contents: String) {
        self.token = token
        self.contents = contents
    }

    func render(_ context: Stencil.Context) throws -> String {
        let operation = try SetOperation(string: contents)
        context[operation.identifier] = try operation.result.eval(context)
        return ""
    }

}
