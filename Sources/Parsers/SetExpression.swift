//
//  File.swift
//
//
//  Created by Jason Barrie Morley on 19/07/2023.
//

import Foundation

import Ogma

// Symbol?
// Variable?
// Identifiers? <- this one?

// TODO: Quoted String is a different expression?

public indirect enum SetExpression {

    public struct Operation {
        let lhs: SetExpression
        let rhs: SetExpression
    }

    public struct Identifier {
        let name: String
    }

    case operation(Operation)
    case identifier(Identifier)
    case int(Int)
    case string(String)
    case double(Double)

}

extension SetExpression {

    struct Result {
        let name: String
        let value: Any?
    }

    // TODO: This needs to take a context for callables.
    // TODO: This should probably actually transform it into a nice structure that can _then_ be evaluated.
    //       Perhaps a block that takes a context?
    // Maybe this extension lives outside of the expression?
    func eval() -> Any? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        default:
            return nil
        }
    }

    // TODO: This shouldn't be necessary!
    func name() -> String? {
        switch self {
        case .identifier(let identifier):
            return identifier.name
        default:
            return nil
        }
    }

    func result() -> Result? {
        switch self {
        case .operation(let operation):
            return Result(name: operation.lhs.name()!, value: operation.rhs.eval())
        default:
            return nil
        }
    }

}

extension SetExpression {

    public enum Token: TokenProtocol {
        case set
        case equals
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

extension SetExpression.Operation: Parsable {
    public static let parser: AnyParser<SetExpression.Token, SetExpression.Operation> = {

        let result = Int.map(SetExpression.int) || Double.map(SetExpression.double) || String.map(SetExpression.string)
        let expression = SetExpression.Identifier.map(SetExpression.identifier) && .equals && result

        return (.set && expression)
            .map { Self(lhs: $0, rhs: $1) }
    }()
}

extension SetExpression: Parsable {
    public static let parser: AnyParser<SetExpression.Token, SetExpression> = SetExpression.Operation.map(SetExpression.operation)
}
