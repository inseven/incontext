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

public struct DateParser {

    static let `default` = DateParser()

    // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    private static let formats = [
        "yyyy'-'MM'-'dd'T'HH':'mm':'sszzzz",
        "yyyy'-'MM'-'dd' 'HH':'mm':'sszzzzz",  // 2014-10-12 18:01:18+01:00
        "yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'zzzzz",
        "yyyy'-'MM'-'dd' 'HH':'mm':'ss", // 2016-11-04 03:19:04
        "yyyy'-'MM'-'dd'", // 2016-11-23
        "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSSzzzzz",
        "yyyy'-'MM'-'dd' 'HH':'mm':'ss'.'SSSSSS", // 2017-07-03 09:38:22.602694
    ]

    private let formatters = formats
        .map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = .gmt
            return formatter
        }

    public init() {

    }

    public func date(from string: String) -> Date? {
        for formatter in formatters {
            guard let date = formatter.date(from: string) else {
                continue
            }
            return date
        }
        return nil
    }

}
