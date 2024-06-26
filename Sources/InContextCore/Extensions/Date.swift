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

import PlatformSupport

extension Date: EvaluationContext {

    var millisecondsSinceReferenceDate: Int {
        return Int(timeIntervalSinceReferenceDate * 1000)
    }

    init(millisecondsSinceReferenceDate: Int) {
        let timeInterval: TimeInterval = Double(millisecondsSinceReferenceDate) / 1000.0
        self.init(timeIntervalSinceReferenceDate: timeInterval)
    }

    func lookup(_ name: String) throws -> Any? {
        switch name {
        case "format": return Function { (format: String) -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: self)
        }
        case "timeIntervalSinceReferenceDate": return Function { () -> Int in
            return Int(self.timeIntervalSinceReferenceDate)
        }
        default:
            throw InContextError.unknownSymbol(name)
        }
    }

}

extension Date: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        try fingerprint.update(millisecondsSinceReferenceDate)
    }

}
