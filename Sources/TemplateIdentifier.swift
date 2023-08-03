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

class TemplateIdentifier: RawRepresentable, Equatable, Codable, Hashable, CustomStringConvertible {

    let language: TemplateLanguage
    let name: String

    var rawValue: String {
        return "\(language.rawValue):\(name)"
    }

    var description: String {
        return rawValue
    }

    init(_ language: TemplateLanguage, _ name: String) {
        self.language = language
        self.name = name
    }

    required init?(rawValue: String) {
        let components = rawValue.split(separator: /\s*:\s*/, maxSplits: 1)
        guard components.count == 2,
              let language = TemplateLanguage(rawValue: String(components[0]))
        else {
            // In order to support legacy Jinja 2 based InContext sites (probably only jbmorley.co.uk), template names
            // without an explicit language are assumed to be Stencil templates as this is the closest in behaviour to
            // Jinja 2.
            self.language = .tilt
            self.name = rawValue
            return
        }
        self.language = language
        self.name = String(components[1])
    }

}

extension TemplateIdentifier {

    static func stencil(_ name: String) -> TemplateIdentifier {
        return TemplateIdentifier(.stencil, name)
    }

    static func tilt(_ name: String) -> TemplateIdentifier {
        return TemplateIdentifier(.tilt, name)
    }

}

extension TemplateIdentifier: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        try fingerprint.update(rawValue)
    }

}
