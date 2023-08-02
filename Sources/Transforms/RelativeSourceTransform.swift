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

import SwiftSoup

struct RelativeSourceTransform: Transformer {

    let selector: String
    let attribute: String

    func transform(store: QueryTracker, document: DocumentContext, content: SwiftSoup.Document) throws {
        for element in try content.select(selector) {
            guard element.hasAttr(attribute) else {
                continue
            }
            let value = try element.attr(attribute)
            // TODO: This should not make a change if path is a fully qualified URL.
            guard !value.hasPrefix("/") else {
                continue
            }

            let newValue = document.relativeSourcePath(for: value)
            print("!!!!!!!")
            print(newValue)
            try element.attr(attribute, newValue)
        }
    }

}
