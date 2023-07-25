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
        do {
            let operation = try SetOperation(string: contents)
            let value = try operation.result.eval(context)
            context[operation.identifier] = value
        } catch {
            print("Failed to evaluate set operation '\(contents)'.")
            throw error
        }
        return ""
    }

}
