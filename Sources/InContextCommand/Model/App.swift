// MIT License
//
// Copyright (c) 2016-2026 Jason Morley
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

#if os(Linux)
import InContextMetadata
#else
import Diligence
#endif

struct App {

#if os(Linux)
    static let version = String(cString: kMetadataVersion)
    static let buildNumber = String(cString: kMetadataBuildNumber)
#else
    static let version = Bundle.main.version ?? "0.0.0"
    static let buildNumber = Bundle.main.build ?? "0"
#endif

#if DEBUG
    static let isDebug = true
#else
    static let isDebug = false
#endif

    static let fullyQualifiedVersion: String = {
        var components: [String] = [App.version, App.buildNumber]
        if isDebug {
            components.append("debug")
        }
        return components.joined(separator: " ")
    }()

}
