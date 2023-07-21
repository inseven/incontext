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

class DummyEnvironment: EvaluationContext {

    func evaluate(call: FunctionCall) -> Any? {
        return "GORGONZOLA"
    }

}

// TODO: Could return KeyValuePairs as the generic solution for args though this needs to be typed somehow?

// TODO: Consider renaming this to template callable
@dynamicCallable
protocol DynamicCallable {
    func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, Any>) -> Any?
}


struct EchoCallable: DynamicCallable {

    func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, Any>) -> Any? {
        return nil
    }


}

extension FunctionCall {

    var methodSignature: String {
        let components: [String] = [name] + self.arguments.map { $0.0 }
        return components.joined(separator: ":") + ":"
    }

}

extension Context: EvaluationContext {

    func evaluate(call: FunctionCall) throws -> Any? {
        guard let instance = self[call.name] else {
            // TODO: Throw a better error.
            throw InContextError.unknown
        }
        guard let object = instance as? NSObject else {
            // TODO: Throw a meaningful error so we understand that this doesn't conform.
            throw InContextError.unknown
        }
        let arguments = try call.arguments.map { (_, resultable) in
            try resultable.eval(self)
        }
        return nil
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
        context[operation.identifier] = try operation.result.eval(DummyEnvironment())
        return ""
    }

}
