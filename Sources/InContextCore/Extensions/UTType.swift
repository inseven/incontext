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

#if canImport(UniformTypeIdentifiers)

import UniformTypeIdentifiers

extension UTType {

    static let markdown: UTType = UTType(mimeType: "text/markdown", conformingTo: .text)!

}

#else

class UTType {

    let filenameExtension: String

    init(filenameExtension: String) {
        self.filenameExtension = filenameExtension
    }

    func conforms(to type: UTType) -> Bool {
        return type.filenameExtension == filenameExtension
    }

}


extension UTType {

    static let markdown: UTType = UTType(filenameExtension: "markdown")
    static let html: UTType = UTType(filenameExtension: "html")
    static let jpeg: UTType = UTType(filenameExtension: "jpeg")
    static let tiff: UTType = UTType(filenameExtension: "tiff")
    static let heic: UTType = UTType(filenameExtension: "heic")

}

#endif
