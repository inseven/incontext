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

import XCTest
@testable import ic3

class ParserTests: XCTestCase {

    func testTrue() {
        XCTAssertTrue(true)
    }

    // TODO: None / nil

    func testParseInt() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = 2"),
                       SetOperation(identifier: "cheese", result: .int(2)))
    }

    func testParseDouble() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = 3.14"),
                       SetOperation(identifier: "cheese", result: .double(3.14)))
    }

    func testParseString() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = \"two\""),
                       SetOperation(identifier: "cheese", result: .string("two")))
    }

    func testParseBoolTrue() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = true"),
                       SetOperation(identifier: "cheese", result: .bool(true)))
    }

    func testParseBoolFalse() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = false"),
                       SetOperation(identifier: "cheese", result: .bool(false)))
    }

    func testParseBoolCamelCaseTrue() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = True"),
                       SetOperation(identifier: "cheese", result: .bool(true)))
    }

    func testParseBoolCamelCaseFalse() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = False"),
                       SetOperation(identifier: "cheese", result: .bool(false)))
    }

    func testParseEmptyArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = []"),
                       SetOperation(identifier: "cheese", result: .array([])))
    }

    func testParseSingleItemStringArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = [\"one\"]"),
                       SetOperation(identifier: "cheese", result: .array([.string("one")])))
    }

    func testParseSingleItemIntArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = [42]"),
                       SetOperation(identifier: "cheese", result: .array([.int(42)])))
    }

    func testParseSingleItemDoubleArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = [3.14]"),
                       SetOperation(identifier: "cheese", result: .array([.double(3.14)])))
    }

    func testParseStringArray() throws {
        let operation = try SetOperation(string: "set cheese = [\"one\", \"two\"]")
        XCTAssertEqual(operation,
                       SetOperation(identifier: "cheese", result: .array([.string("one"), .string("two")])))
        XCTAssertEqual(try operation.result.eval([AnyHashable: Any]()) as? [String], ["one", "two"])
    }

    func testNestedArray() throws {
        let operation = try SetOperation(string: "set cheese = [\"one\", [2, 3.0]]")
        XCTAssertEqual(operation,
                       SetOperation(identifier: "cheese", result: .array([.string("one"),
                                                                          .array([.int(2), .double(3.0)])])))
        XCTAssertEqual(try operation.result.eval([AnyHashable: Any]()) as? NSArray,
                       ["one", [2, 3.0]] as NSArray)
    }

    func testParseIntArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = [1, 2]"),
                       SetOperation(identifier: "cheese", result: .array([.int(1), .int(2)])))
    }

    func testParseMixedArray() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = [1, \"two\", 3.0]"),
                       SetOperation(identifier: "cheese", result: .array([.int(1), .string("two"), .double(3.0)])))
    }

    func testParseEmptyDictionary() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = {}"),
                       SetOperation(identifier: "cheese", result: .dictionary([:])))
    }

    func testSingleValueDictionary() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = {\"foo\": \"bar\"}"),
                       SetOperation(identifier: "cheese", result: .dictionary([.string("foo"): .string("bar")])))
    }

    func testMixedValueDictionary() throws {
        XCTAssertEqual(try SetOperation(string: "set cheese = {\"foo\": \"bar\", 12: 42.0}"),
                       SetOperation(identifier: "cheese", result: .dictionary([.string("foo"): .string("bar"),
                                                                               .int(12): .double(42.0)])))
    }

    func testParseFunction() throws {
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: nil,
                                                              operation: .call(.init(name: "titlecase",
                                                                                     arguments: [])))))
        XCTAssertEqual(try SetOperation(string: "set cheese = titlecase()"), expected)
    }

    func testParseFunctionWithSingleArgument() throws {
        let arguments = [NamedResultable(name: "name", result: .string("fromage"))]
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: nil,
                                                              operation: .call(.init(name: "titlecase",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cheese = titlecase(name: \"fromage\")"), expected)
    }

    func testParseFunctionMultipleIntArguments() throws {
        let arguments = [NamedResultable(name: "one", result: .int(1)),
                         NamedResultable(name: "two", result: .int(2))]
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: nil,
                                                              operation: .call(.init(name: "call",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cheese = call(one: 1, two: 2)"), expected)
    }

    func testParseFunctionMultipleStringArguments() throws {
        let arguments = [NamedResultable(name: "one", result: .string("1")),
                         NamedResultable(name: "two", result: .string("2"))]
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: nil,
                                                              operation: .call(.init(name: "call",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cheese = call(one: \"1\", two: \"2\")"), expected)
    }

    func testParseLookupAndFunctionMultipleStringArguments() throws {
        let object = Resultable.executable(.init(operand: nil,
                                                operation: .lookup("object")))
        let arguments = [NamedResultable(name: "one", result: .string("1")),
                         NamedResultable(name: "two", result: .string("2"))]
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: object,
                                                              operation: .call(.init(name: "call",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cheese = object.call(one: \"1\", two: \"2\")"), expected)
    }

    func testParseArgumentsWithNumbers() throws {
        let object = Resultable.executable(.init(operand: nil,
                                                operation: .lookup("object")))
        let arguments = [NamedResultable(name: "str1", result: .string("abc")),
                         NamedResultable(name: "str2", result: .string("def"))]
        let expected = SetOperation(identifier: "value",
                                    result: .executable(.init(operand: object,
                                                              operation: .call(.init(name: "prefix",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set value = object.prefix(str1: \"abc\", str2: \"def\")"), expected)
    }

    func testParseFunctionWithNumberedArgument() throws {
        let arguments = [NamedResultable(name: "arg1", result: .string("cats"))]
        let expected = SetOperation(identifier: "cute",
                                    result: .executable(.init(operand: nil,
                                                              operation: .call(.init(name: "call",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cute = call(arg1: \"cats\")"), expected)
    }

    func testParseSymbol() throws {
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: nil,
                                                              operation: .lookup("foo"))))
        XCTAssertEqual(try SetOperation(string: "set cheese = foo"), expected)
    }

    func testParseKeyPath() throws {
        let fooLookup = Resultable.executable(.init(operand: nil,
                                                    operation: .lookup("foo")))
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: fooLookup,
                                                              operation: .lookup("bar"))))
        XCTAssertEqual(try SetOperation(string: "set cheese = foo.bar"), expected)
    }

    func testParseLookupAndCall() throws {
        let fooLookup = Resultable.executable(.init(operand: nil,
                                                    operation: .lookup("foo")))
        let call = FunctionCall(name: "bar", arguments: [])
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: fooLookup,
                                                              operation: .call(call))))
        XCTAssertEqual(try SetOperation(string: "set cheese = foo.bar()"), expected)
    }

    func testParseStringWithCall() throws {
        let arguments = [NamedResultable(name: "name", result: .string("fromage"))]
        let expected = SetOperation(identifier: "cheese",
                                    result: .executable(.init(operand: .string("fromage"),
                                                              operation: .call(.init(name: "titlecase",
                                                                                     arguments: arguments)))))
        XCTAssertEqual(try SetOperation(string: "set cheese = \"fromage\".titlecase(name: \"fromage\")"), expected)
    }

    func testMultiLevelFunctionCall() throws {
        let post = Executable(operand: nil, operation: .lookup("post"))
        let date = Executable(operand: .executable(post), operation: .lookup("date"))
        let format = Executable(operand: .executable(date), operation: .call(FunctionCall(name: "format", arguments: [NamedResultable(name: "string", result: .string("YYYY"))])))
        let expected = SetOperation(identifier: "last_year", result: .executable(format))
        XCTAssertEqual(try SetOperation(string: "set last_year = post.date.format(string: \"YYYY\")"), expected)
    }

    func testExecutableAppy() throws {
        // a.b.c.foo()
        let foo = Executable(operand: nil, operation: .call(FunctionCall(name: "foo")))
        let c = Executable(operand: nil, operation: .lookup("c"))
        let c_foo = try foo.apply(to: .executable(c))

        XCTAssertEqual(c_foo, Executable(operand: .executable(c),
                                         operation: .call(FunctionCall(name: "foo"))))

        let b = Executable(operand: nil, operation: .lookup("b"))
        let b_c_foo = try c_foo.apply(to: .executable(b))
        print(String(describing: b_c_foo))
        XCTAssertEqual(b_c_foo,
                       Executable(operand: .executable(Executable(operand: .executable(b), operation: .lookup("c"))),
                                   operation: .call(FunctionCall(name: "foo"))))

    }

    // TODO: foo."hello" should fail
    // TODO: foo.bar().baz
    // TODO: foo.bar().echo(string: "value")

    func testUpdate() throws {
        XCTAssertEqual(try UpdateOperation(string: "update cheese = 2"),
                       UpdateOperation(identifier: "cheese", result: .int(2)))
    }

}

extension FunctionCall {

    init(name: String) {
        self.init(name: name, arguments: [])
    }

}
