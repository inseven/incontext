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

// Structured site settings.
// This is currently only used to parse a known-structured part of the site settings, but it should ultimately handle
// all configuration.
struct Settings: Decodable {

    struct Location: Codable {
        let title: String
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case title
        case author
        case url
        case metadata
        case port
        case favorites
    }

    let version: Int
    let title: String
    let author: String?
    let url: URL
    let metadata: [String: Any]
    let port: Int
    let favorites: [String: Location]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw InContextError.internalInconsistency("Unsupported settings version (\(version)).")
        }
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.url = try container.decode(URL.self, forKey: .url)
        self.metadata = try container.decodeIfPresent(Dictionary<String, Any>.self, forKey: .metadata) ?? [:]
        self.port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 8000
        self.favorites = try container.decodeIfPresent([String: Location].self, forKey: .favorites) ?? [:]
    }

}
