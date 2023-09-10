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

// TODO: Promote a structured location
// TODO: Promote a structure queries

import Foundation

struct Frontmatter: Decodable {

    // TODO: Consider not using this?
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case category
        case template
        case title
        case subtitle
        case date
        case thumbnail
        case tags
        case queries
        case metadata
    }

    let category: String?
    let template: TemplateIdentifier?
    let title: String?
    let subtitle: String?
    let date: Date?
    let thumbnail: String?
    let tags: [String]?
    let queries: [String: QueryDescription]
    let metadata: [String: Any]

    init(category: String? = nil,
         template: TemplateIdentifier? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         date: Date? = nil,
         thumbnail: String? = nil,
         tags: [String]? = nil,
         queries: [String: QueryDescription] = [:],
         metadata: [String: Any] = [:]) {
        self.category = category
        self.template = template
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.thumbnail = thumbnail
        self.tags = tags
        self.queries = queries
        self.metadata = metadata
    }

    init(from decoder: Decoder) throws {

        // Check to see if the container has unknown keys.
        // Although unconventional, we do this to make it easier for users to understand why data isn't
        // flowing through from their input files to template renders.
        let knownKeys = Set(CodingKeys.allCases.map { $0.stringValue })
        for key in try decoder.allKeys {
            guard knownKeys.contains(key) else {
                print("Frontmatter contains unknown key '\(key)'.")
                throw InContextError.internalInconsistency("Frontmatter contains unknown key '\(key)'.")
            }
        }

        // Actually decode the data.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.template = try container.decodeIfPresent(TemplateIdentifier.self, forKey: .template)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date)
        self.thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.queries = try container.decodeIfPresent([String: QueryDescription].self, forKey: .queries) ?? [:]
        self.metadata = try container.decodeIfPresent(Dictionary<String, Any>.self, forKey: .metadata) ?? [:]
    }

}
