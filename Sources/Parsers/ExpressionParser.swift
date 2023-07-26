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

public indirect enum ExpressionParser {

    public struct Identifier {
        let name: String
    }

    case operation(SetOperation)
}

extension ExpressionParser {

    public enum Token: TokenProtocol {
        case set
        case update
        case equals
        case colon
        case comma
        case dot
        case openParenthesis
        case closeParenthesis
        case openSquareBracket
        case closeSquareBracket
        case openBrace
        case closeBrace
        case `true`
        case `false`
        case int(Int)
        case double(Double)
        case string(String)
        case identifier(String)
    }

}

extension ExpressionParser {

    enum Lexer: GeneratorLexer {
        typealias Token = ExpressionParser.Token

        static let generators: Generators = [
            WhiteSpaceTokenGenerator().ignore(),
            RegexTokenGenerator(pattern: "set").map(to: .set),
            RegexTokenGenerator(pattern: "update").map(to: .update),
            RegexTokenGenerator(pattern: "=").map(to: .equals),
            RegexTokenGenerator(pattern: "\\.").map(to: .dot),
            RegexTokenGenerator(pattern: ":").map(to: .colon),
            RegexTokenGenerator(pattern: ",").map(to: .comma),
            RegexTokenGenerator(pattern: "\\(").map(to: .openParenthesis),
            RegexTokenGenerator(pattern: "\\)").map(to: .closeParenthesis),
            RegexTokenGenerator(pattern: "\\[").map(to: .openSquareBracket),
            RegexTokenGenerator(pattern: "\\]").map(to: .closeSquareBracket),
            RegexTokenGenerator(pattern: "\\{").map(to: .openBrace),
            RegexTokenGenerator(pattern: "\\}").map(to: .closeBrace),
            RegexTokenGenerator(pattern: "true|True\\b").map(to: .true),
            RegexTokenGenerator(pattern: "false|False\\b").map(to: .false),
            RegexTokenGenerator(pattern: "[a-zA-Z_][a-zA-Z0-9_]*").map(Token.identifier),
            IntLiteralTokenGenerator().map(Token.int),
            DoubleLiteralTokenGenerator().map(Token.double),
            StringLiteralTokenGenerator().map(Token.string),
        ]
    }

}

extension ExpressionParser.Token {

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

    var identifier: ExpressionParser.Identifier? {
        guard case .identifier(let name) = self else { return nil }
        return ExpressionParser.Identifier(name: name)
    }

}

extension Int: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = .consuming(keyPath: \.int)
}

extension Double: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = .consuming(keyPath: \.double)
}

extension String: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = .consuming(keyPath: \.string)
}

extension Bool: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = Token.true.map { true } || Token.false.map { false }
}

extension Array: Parsable where Element == Resultable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let element = Resultable.map { $0 }
        let elements = element
            .separated(by: .comma, allowsTrailingSeparator: false, allowsEmpty: true)
            .map { $0 }
            .wrapped(by: .openSquareBracket, and: .closeSquareBracket)
        return elements
    }()
}

extension Dictionary: Parsable where Key == Resultable, Value == Resultable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let element = Resultable.self && .colon && Resultable.self
        return element
            .separated(by: .comma, allowsTrailingSeparator: false, allowsEmpty: true)
            .map { Dictionary($0, uniquingKeysWith: { $1 }) }
            .wrapped(by: .openBrace, and: .closeBrace)
    }()
}

extension ExpressionParser.Identifier: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, ExpressionParser.Identifier> = .consuming(keyPath: \.identifier)
}

extension SetOperation {
    init(string: String) throws {
        self = try Self.parse(string, using: ExpressionParser.Lexer.self)
    }
}

extension UpdateOperation {
    init(string: String) throws {
        self = try Self.parse(string, using: ExpressionParser.Lexer.self)
    }
}

extension Resultable: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let int = Int.map { Self.int($0) }
        let double = Double.map { Self.double($0) }
        let string = String.map { Self.string($0) }
        let bool = Bool.map { Self.bool($0) }
        let executable = Executable.map { Self.executable($0) }
        let array = Array<Resultable>.map { Self.array($0) }
        let dictionary = Dictionary<Resultable, Resultable>.map { Self.dictionary($0) }
        return executable || int || double || string || bool || array || dictionary
    }()
}

extension Operation: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let functionCall = FunctionCall.map { Self.call($0) }
        let lookup = ExpressionParser.Identifier.map { Self.lookup($0.name) }
        let expression = functionCall || lookup
        return expression.map { $0 }
    }()
}

extension Executable: Parsable {

    // TODO: Guard against unintentional iterals in after a dot.
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let head = Resultable.map { $0 }
        let tail = Executable.map { $0 }
        let expression = head && .dot && tail
        let common = expression.map { try $1.apply(to: $0) }
        let base = Operation.map { Self(operand: nil, operation: $0) }
        return (common || base).map { $0 }
    }()

}

extension FunctionCall: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let name = ExpressionParser.Identifier.map { $0.name }
        let result = Resultable.map { $0 }
        let argument = (name && .colon && result)
        let cheese = argument.map { NamedResultable(name: $0, result: $1) }
        let arguments = cheese
            .separated(by: .comma, allowsTrailingSeparator: false, allowsEmpty: true)
            .map { $0 }
            .wrapped(by: .openParenthesis, and: .closeParenthesis)
        let call = ExpressionParser.Identifier.map { $0.name } && arguments
        return call
            .map { FunctionCall(name: $0, arguments: $1) }
    }()
}

extension SetOperation: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let identifier = ExpressionParser.Identifier.map { $0.name }
        let result = Resultable.map { $0 }
        let expression = identifier && .equals && result
        return (.set && expression)
            .map { Self(identifier: $0, result: $1) }
    }()
}

extension UpdateOperation: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = {
        let identifier = ExpressionParser.Identifier.map { $0.name }
        let result = Resultable.map { $0 }
        let expression = identifier && .equals && result
        return (.update && expression)
            .map { Self(identifier: $0, result: $1) }
    }()
}

extension ExpressionParser: Parsable {
    public static let parser: AnyParser<ExpressionParser.Token, Self> = SetOperation.map(ExpressionParser.operation)
}
