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

import Ogma

public indirect enum SetExpression {

    public struct Identifier {
        let name: String
    }

    case operation(SetOperation)
    case identifier(Identifier)
    case int(Int)
    case string(String)
    case double(Double)
}

extension SetExpression {

    public enum Token: TokenProtocol {
        case set
        case equals
        case colon
        case comma
        case openParenthesis
        case closeParenthesis
        case int(Int)
        case double(Double)
        case string(String)
        case identifier(String)
    }

}

extension SetExpression {

    enum Lexer: GeneratorLexer {
        typealias Token = SetExpression.Token

        static let generators: Generators = [
            WhiteSpaceTokenGenerator().ignore(),
            RegexTokenGenerator(pattern: "set").map(to: .set),
            RegexTokenGenerator(pattern: "=").map(to: .equals),
            RegexTokenGenerator(pattern: ":").map(to: .colon),
            RegexTokenGenerator(pattern: "\\(").map(to: .openParenthesis),
            RegexTokenGenerator(pattern: "\\)").map(to: .closeParenthesis),
            RegexTokenGenerator(pattern: ",").map(to: .comma),
            RegexTokenGenerator(pattern: "[a-zA-Z]+").map(Token.identifier),
            IntLiteralTokenGenerator().map(Token.int),
            DoubleLiteralTokenGenerator().map(Token.double),
            StringLiteralTokenGenerator().map(Token.string),
        ]
    }

}

extension SetExpression.Token {

    var int: Int? {
        guard case .int(let int) = self else { return nil }
        return int
    }

    var double: Double? {
        guard case .double(let double) = self else { return nil }
        return double
    }

    var string: String? {
        guard case .string(let string) = self else { return nil }
        return string
    }

    var identifier: SetExpression.Identifier? {
        guard case .identifier(let name) = self else { return nil }
        return SetExpression.Identifier(name: name)
    }

}

extension Int: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Int> = .consuming(keyPath: \.int)
}

extension Double: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Double> = .consuming(keyPath: \.double)
}

extension String: Parsable {
    public static let parser: AnyParser<SetExpression.Token, String> = .consuming(keyPath: \.string)
}

extension SetExpression.Identifier: Parsable {
    public static let parser: AnyParser<SetExpression.Token, SetExpression.Identifier> = .consuming(keyPath: \.identifier)
}

extension SetOperation {
    init(string: String) throws {
        self = try Self.parse(string, using: SetExpression.Lexer.self)
    }
}

extension Resultable: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Self> = {
        let int = Int.map { Self.int($0) }
        let double = Double.map { Self.double($0) }
        let string = String.map { Self.string($0) }
        let functionCall = FunctionCall.map { Self.call($0) }
        return int || double || string || functionCall
    }()
}

extension FunctionCall: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Self> = {
        let name = SetExpression.Identifier.map { $0.name }
        let result = Resultable.map { $0 }
        let argument = name && .colon && result
        let arguments = argument
            .separated(by: .comma, allowsTrailingSeparator: false, allowsEmpty: true)
            .map { $0 }
            .wrapped(by: .openParenthesis, and: .closeParenthesis)
        let call = SetExpression.Identifier.map { $0.name } && arguments
        return call
            .map { FunctionCall(name: $0, arguments: $1) }
    }()
}

extension SetOperation: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Self> = {
        let identifier = SetExpression.Identifier.map { $0.name }
        let result = Resultable.map { $0 }
        let expression = identifier && .equals && result
        return (.set && expression)
            .map { Self(identifier: $0, result: $1) }
    }()
}

extension SetExpression: Parsable {
    public static let parser: AnyParser<SetExpression.Token, Self> = SetOperation.map(SetExpression.operation)
}
