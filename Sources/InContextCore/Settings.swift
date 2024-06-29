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

// Structured site settings.
// This is currently only used to parse a known-structured part of the site settings, but it should ultimately handle
// all configuration.
struct Settings: Codable {

    struct Location: Codable {
        let title: String
    }

    struct Action: Codable {
        let name: String?
        let run: String
    }

    struct ImportStep: Decodable {

        private enum CodingKeys: String, CodingKey {
            case when
            case then
            case args
        }

        let when: String
        let then: String
        let args: [String: Any]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.when = try container.decode(String.self, forKey: .when)
            self.then = try container.decode(String.self, forKey: .then)
            self.args = try container.decodeIfPresent([String: Any].self, forKey: .args) ?? [:]
        }
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case title
        case author
        case url
        case metadata
        case port
        case steps
    }

    let version: Int
    let title: String
    let author: String?
    let url: URL
    let metadata: [String: Any]
    let port: Int
    let steps: [ImportStep]

    init(version: Int,
         title: String,
         author: String? = nil,
         url: URL,
         metadata: [String: Any] = [:],
         port: Int,
         actions: [String: Action] = [:],
         steps: [ImportStep] = []) {
        self.version = version
        self.title = title
        self.author = author
        self.url = url
        self.metadata = metadata
        self.port = port
        self.steps = steps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        guard version == 2 else {
            throw InContextError.internalInconsistency("Unsupported settings version (\(version)).")
        }
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.url = try container.decode(URL.self, forKey: .url)
        self.metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata) ?? [:]
        self.port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 8000
        self.steps = try container.decode([ImportStep].self, forKey: .steps)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Settings.CodingKeys.self)
        try container.encode(self.title, forKey: Settings.CodingKeys.title)
    }

}
