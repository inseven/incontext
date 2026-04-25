// MIT License
//
// Copyright (c) 2016-2024 Jason Morley
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

protocol _Test {
    func evaluate(fileURL: URL) -> Bool
}

struct _True: _Test {
    func evaluate(fileURL: URL) -> Bool {
        return true
    }
}

struct _Or<A: _Test, B: _Test>: _Test {

    let lhs: A
    let rhs: B

    init(_ lhs: A, _ rhs: B) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func evaluate(fileURL: URL) -> Bool {
        return lhs.evaluate(fileURL: fileURL) || rhs.evaluate(fileURL: fileURL)
    }

}

func ||<T: _Test, Q: _Test>(lhs: T, rhs: Q) -> _Or<T, Q> {
    return _Or(lhs, rhs)
}

struct _And<A: _Test, B: _Test>: _Test {

    let lhs: A
    let rhs: B

    init(_ lhs: A, _ rhs: B) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func evaluate(fileURL: URL) -> Bool {
        return lhs.evaluate(fileURL: fileURL) && rhs.evaluate(fileURL: fileURL)
    }

}

func &&<T: _Test, Q: _Test>(lhs: T, rhs: Q) -> _And<T, Q> {
    return _And(lhs, rhs)
}

struct _Metadata: _Test {

    let key: String
    let value: String

    init(_ key: String, equals value: String) {
        self.key = key
        self.value = value
    }

    func evaluate(fileURL: URL) -> Bool {
        return true
    }

}

struct TransformContext {

    let fileURL: URL
    let imageSource: ImageSource
    let exif: EXIF

    let assetsURL: URL

    var metadata: [String: Any]
    var assets: [Asset]

}
