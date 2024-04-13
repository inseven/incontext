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

// InContext permits additional metadata, but expects some structured keys to be of specific types.
struct Metadata: Codable {

    let category: String?
    let template: String?
    let title: String?
    let subtitle: String?
    let date: Date?
    let tags: [String]?

    init(category: String? = nil,
         template: String? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         date: Date? = nil,
         tags: [String]? = nil) {
        self.category = category
        self.template = template
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.tags = tags
    }

}
