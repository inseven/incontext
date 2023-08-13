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

import Crypto

struct Fingerprint {

    public enum CryptoError: Error {
        case encodingError
    }

    private var md5: Insecure.MD5

    init() {
        md5 = Insecure.MD5()
    }

    mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        md5.update(bufferPointer: bufferPointer)
    }

    mutating func update(_ fingerprintable: Fingerprintable) throws {
        try fingerprintable.combine(into: &self)
    }

    mutating func update(_ int: Int) throws {
        var int = int
        withUnsafeBytes(of: &int) { data in
            self.update(bufferPointer: data)
        }
    }

    mutating func update(_ float: Float) throws {
        var float = float
        withUnsafeBytes(of: &float) { data in
            self.update(bufferPointer: data)
        }
    }

    mutating func update(_ double: Double) throws {
        var double = double
        withUnsafeBytes(of: &double) { data in
            self.update(bufferPointer: data)
        }
    }

    mutating func update(_ bool: Bool) throws {
        var bool = bool
        withUnsafeBytes(of: &bool) { data in
            self.update(bufferPointer: data)
        }
    }

    mutating func update(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw CryptoError.encodingError
        }
        md5.update(data: data)
    }

    mutating func update(_ date: Date) throws {
        var date = date.timeIntervalSinceReferenceDate
        withUnsafeBytes(of: &date) { data in
            self.update(bufferPointer: data)
        }
    }

    func finalize() -> String {
        let digest = md5.finalize()
        let data = Data(digest)
        return data.base64EncodedString()
    }

}
