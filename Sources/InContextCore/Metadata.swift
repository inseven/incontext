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

    enum CodingKeys: CodingKey {
        case category
        case template
        case title
        case subtitle
        case date
        case tags
    }

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

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.template = try container.decodeIfPresent(String.self, forKey: .template)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.date = try container.decodeIfPresent(PermissiveDate.self, forKey: .date)?.date
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.category, forKey: .category)
        try container.encodeIfPresent(self.template, forKey: .template)
        try container.encodeIfPresent(self.title, forKey: .title)
        try container.encodeIfPresent(self.subtitle, forKey: .subtitle)
        try container.encodeIfPresent(self.date, forKey: .date)
        try container.encodeIfPresent(self.tags, forKey: .tags)
    }

}
