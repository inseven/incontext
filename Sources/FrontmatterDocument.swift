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

import MarkdownKit
import Yaml

struct FrontmatterDocument {

    private static let frontmatterRegEx = /(?s)^(-\-\-\n)(?<metadata>.*?)(-\-\-\n)(?<content>.*)$/

    let metadata: Dictionary<AnyHashable, Any>
    let content: String

    init(contents: String, generateHTML: Bool = false) throws {
        guard let match = contents.wholeMatch(of: Self.frontmatterRegEx) else {
            metadata = [:]
            content = generateHTML ? contents.html() : contents
            return
        }
        metadata = try String(match.metadata).parseYAML()
        content = generateHTML ? String(match.content).html() : String(match.content)
    }

}

extension String {

    func html() -> String {
        let markdown = ExtendedMarkdownParser.standard.parse(self)
        let html = HtmlGenerator.standard.generate(doc: markdown)
        return html
    }

}

extension StringProtocol {

    func parseYAML() throws -> [AnyHashable: Any] {
        // TODO: Do this inline.
        let yaml = try Yaml.load(String(self))
        return try yaml.dictionary()
    }

}

extension Yaml {

    func dictionary() throws -> [AnyHashable: Any] {
        guard let dictionary = native() as? [AnyHashable: Any] else {
            throw InContextError.invalidMetadata
        }
        return dictionary
    }

    func native() -> Any? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .array(let values):
            return values.compactMap {  // TODO: Is compact map safe here?
                $0.native()
            }
        case .dictionary(let values):
            // TODO: Is a compact map too permissive?
            let nativeValues: [(AnyHashable, Any)] = values.compactMap { (key, value) in  // TODO: Compact map?
                guard let key = key.native() as? AnyHashable,
                      let value = value.native() else {
                    return nil
                }
                return (key, value)
            }
            return nativeValues.reduce(into: [AnyHashable:Any]()) { partialResult, item in
                partialResult[item.0] = item.1
            }

        }
    }

}
