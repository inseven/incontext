//
//  File.swift
//  
//
//  Created by Jason Barrie Morley on 19/07/2023.
//

import Foundation

import XCTest
@testable import ic3

import Stencil

// TODO: Move this into a separate method.
struct TestContext: EvaluationContext {

    // TODO: Consider some form of typesafe subscripted object (think SQLite.swift)
    func evaluate(call: BoundFunctionCall) throws -> Any? {
        if let _ = try call.arguments(Method("jump")) {
            return "*boing*"
        } else if let argument = try call.arguments(Method("titlecase")
            .argument("string", type: String.self)) {
            return argument.toTitleCase()
        } else if let argument = try call.arguments(Method("echo")
            .argument("string", type: String.self)) {
            return argument
        } else if let arguments = try call.arguments(Method("prefix")
            .argument("str1", type: String.self)
            .argument("str2", type: String.self)) {
            return arguments.0 + arguments.1
        }
        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: Throw error
        return nil
    }

}


class RendererTests: XCTestCase {

    func render(_ template: String, context: [String: Any]) throws -> String {
        let environment = Environment(extensions: [Site.ext()])
        return try environment.renderTemplate(string: template, context: context)
    }

    func testSimple() throws {
        XCTAssertEqual(try render("Hello {{ name }}!", context: ["name": "Jason"]),
                       "Hello Jason!")
    }

    // At a guess, Sentcil is using `Mirror` to acheive this. That might be why it's not working for dynamic variables?
    func testProperty() throws {
        struct Person {
            var name = "Jason"
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    func testDynamicPropertyFails() throws {
        class Person {
            var name: String { "Jason" }
            init() { }
        }
        XCTAssertNotEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                          "Hello Jason!")
    }

    // From testing, it seems like Swift dynamic properties don't work out of the box with Stencil. That would make
    // sense as I imagine it's using key-value coding which I believe only works with classes that inherit from
    // NSObject.
    func testObjCDynamicProperty() throws {
        @objc class Person: NSObject {
            @objc var name: String { "Jason" }
            override init() { super.init() }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    func testDictionary() {
        let person = [
            "name": "Jason"
        ]
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": person]),
                       "Hello Jason!")
    }

    // TODO: Check to see if Mirror returns functions and dynamic properties
    // TODO: Check function calls with parameters (probably not)
    // TODO: Test subcontexts as a repalcement for with?
    // TODO: Consider LiquidKit as an alternative

    func testDynamicMemberLookup() {
        class Person: DynamicMemberLookup {
            var name: String { "Jason" }
            subscript(dynamicMember member: String) -> Any? {
                print(member)
                switch member {
                case "name":
                    return name
                default:
                    return nil
                }
            }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    // Similarly to dynamic properties, functions only seem to work with NSObjects and (presumably) key-value lookup,
    // though I guess Mirror might be way more capable in NSObject-land (something to check).
    func testFunction() {
        @objc class Person: NSObject {
            @objc func name() -> String {
                return "Jason"
            }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    // TODO: Bug fix; should always push a context if it's empty at render time.

    func testSetString() {
        XCTAssertEqual(try render("{% set name = \"Jason\" %}Hello {{ name }}!", context: ["tick": "tock"]),
                       "Hello Jason!")
    }

    func testSetInt() {
        XCTAssertEqual(try render("{% set value = 42 %}The answer is {{ value }}!", context: ["tick": "tock"]),
                       "The answer is 42!")
    }

    func testSetDouble() {
        XCTAssertEqual(try render("{% set value = 3.14159 %}Pi = {{ value }}!", context: ["tick": "tock"]),
                       "Pi = 3.14159!")
    }

    func testVariable() {
        XCTAssertEqual(try render("{% set value = tick %}tick = {{ value }}!", context: ["tick": "tock"]),
                       "tick = tock!")
    }

    // TODO: Support assigning with identifiers.

    func testFunctionCall() {
        XCTAssertEqual(try render("{% set value = object.titlecase(string: \"jason\") %}Hello {{ value }}!",
                                  context: ["object": TestContext()]),
                       "Hello Jason!")
    }

    // TODO: Test top-level context function _without_ faked up object.

    func testStringCount() {
        XCTAssertEqual(try render("{% set value = \"cheese\".count %}{{ value }}!",
                                  context: ["object": TestContext()]),
                       "6!")
    }

    func testEchoCallable() {
        XCTAssertEqual(try render("{% set value = object.echo(string: \"jason\") %}{{ value }}",
                                  context: ["object": TestContext()]),
                       "jason")
    }

    func testEchoCallableLookup() {
        XCTAssertEqual(try render("{% set value = object.echo(string: name) %}{{ value }}",
                                  context: ["object": TestContext(), "name": "jason"]),
                       "jason")
    }

    func testEchoCallableChain() {
        XCTAssertEqual(try render("{% set value = object.echo(string: object.echo(string: \"jason\")) %}{{ value }}",
                                  context: ["object": TestContext(), "name": "jason"]),
                       "jason")
    }

    func testMultipleArguments() {
        XCTAssertEqual(try render("{% set value = object.prefix(str1: \"abc\", str2: \"def\") %}{{ value }}",
                                  context: ["object": TestContext()]),
                       "abcdef")
    }

    func testContextWithCallableBlock() {
        let context = [
            "increment": CallableBlock(Method("increment")
                .argument("value", type: Int.self)) { value in
                    return value + 1
                }
        ]
        XCTAssertEqual(try render("{% set value = increment(value: 1) %}{{ value }}",
                                  context: context),
                       "2")
    }

    func testParseSet() throws {
        let operation = try SetOperation(string: "set value = utils.increment(value: 1)")
        let lookup = Executable(operand: nil, operation: .lookup("utils"))
        let call = FunctionCall(name: "increment", arguments: [NamedResultable(name: "value", result: .int(1))])
        let perform = Executable(operand: Resultable.executable(lookup), operation: .call(call))
        let expected = SetOperation(identifier: "value", result: .executable(perform))
        XCTAssertEqual(operation, expected)
    }

    func testContextWithDictionaryContainingCallableBlock() {
        let context = [
            "utils": [
                "increment": CallableBlock(Method("increment").argument("value", type: Int.self)) { value in
                    return value + 1
                }
            ] as Dictionary<String, Any>  // Oh. My. God. Why is this necessary??
        ]
        XCTAssertEqual(try render("{% set value = utils.increment(value: 1) %}{{ value }}",
                                  context: context),
                       "2")
    }


}
