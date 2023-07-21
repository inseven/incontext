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

    func testSetString() {
        // TODO: Bug fix; should always push a context if it's empty at render time.
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

    // TODO: Support assigning with identifiers.

    func testFunctionCall() {
        XCTAssertEqual(try render("{% set value = titlecase(string: \"jason\") %}Hello {{ value }}!", context: ["object": EchoCallable()]),
                       "Hello Jason!")
    }

    // Fails to parse
//    func testFunctionWithParameters() {
//        @objc class Person: NSObject {
//            @objc func name() -> String {
//                return "Jason"
//            }
//        }
//        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
//                       "Hello Jason!")
//    }

}
