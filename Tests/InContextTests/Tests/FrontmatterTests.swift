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

import XCTest
@testable import InContextCore

class FrontmatterTests: XCTestCase {

    func testParseMarkdown() throws {
        let document = try FrontmatterDocument(contents: """
---
template: tags.html
title: Tags
category: pages
queries:
  posts:
    include:
    - general
---
Here's some **Markdown** content
""", generateHTML: true)

        XCTAssertEqual(document.content, "<p>Here&#39;s some <strong>Markdown</strong> content</p>\n")
        let metadata: [AnyHashable: Any] = ["template": "tags.html",
                                            "title": "Tags",
                                            "category": "pages",
                                            "queries":
                                                ["posts":
                                                    ["include":
                                                        ["general"]]]]
        XCTAssertEqual(document.metadata as NSObject, metadata as NSObject)
    }

    func testEmptyFrontmatter() throws {
        let document = try FrontmatterDocument(contents: "**strong**")
        XCTAssertEqual(document.content, "**strong**")
        XCTAssertEqual(document.metadata as NSObject, [AnyHashable: Any]() as NSObject)
    }

    func testEmptyFrontmatterParseHTML() throws {
        let document = try FrontmatterDocument(contents: "**strong**", generateHTML: true)
        XCTAssertEqual(document.content, "<p><strong>strong</strong></p>\n")
        XCTAssertEqual(document.metadata as NSObject, [AnyHashable: Any]() as NSObject)
    }

    func testFrontmatterStandardDate() throws {
        let document = try FrontmatterDocument(contents: """
---
date: '2001-10-02 01:54:02 +01:00'
---
Here's some **Markdown** content
""", generateHTML: true)
        let testDate = Date(2001, 10, 02, 01, 54, 02, timeZone: TimeZone(1)!)
        XCTAssertEqual(document.date, testDate)
    }

    func testFrontmatterAlternativeISOFormatDate() throws {
        let document = try FrontmatterDocument(contents: """
---
date: '2024-01-17T17:53:07-1000'
---
Here's some **Markdown** content
""", generateHTML: true)
        let testDate = Date(2024, 01, 17, 17, 53, 07, timeZone: TimeZone(-10)!)
        XCTAssertEqual(document.date, testDate)
    }

    func testDatePromotion() throws {
        let document = try FrontmatterDocument(contents: """
---
date: '2024-01-17T17:53:07-1000'
title: Hello, World!
end_date: 2024-04-21
---
Here's some **Markdown** content
""", generateHTML: true)
        XCTAssertEqual(document.date,
                       Date(2024, 01, 17, 17, 53, 07, timeZone: TimeZone(-10)!))
        XCTAssertEqual(document.title,
                       "Hello, World!")
        XCTAssertEqual(document.metadata["end_date"] as? Date,
                       Date(2024, 04, 21))

    }

    func testEscapedUnicode() throws {
        let document = try FrontmatterDocument(contents: """
---
date: 2024-04-22T21:39:25.747002006Z
tags:
- coffee
- software
- development
location:
  latitude: 2.15908652921416e+1
  longitude: -1.58102978162547e+2
  locality: "Hale\\u02BBiwa"

---
Let’s see if this actually stores the location for us. This is a post written in Island Vintage in Hale’iwa.
""")
        XCTAssertNotNil(document.metadata["location"])
        let location = document.metadata["location"] as? Dictionary<String, Any>
        XCTAssertEqual(location?["locality"] as? String, "Haleʻiwa")
    }

    func testUnicode() throws {
        let document = try FrontmatterDocument(contents: """
---
date: 2024-04-22T21:39:25.747002006Z
tags:
- coffee
- software
- development
location:
  latitude: 2.15908652921416e+1
  longitude: -1.58102978162547e+2
  locality: "Haleʻiwa"

---
Let’s see if this actually stores the location for us. This is a post written in Island Vintage in Hale’iwa.
""")
        XCTAssertNotNil(document.metadata["location"])
        let location = document.metadata["location"] as? Dictionary<String, Any>
        XCTAssertEqual(location?["locality"] as? String, "Haleʻiwa")
    }

    func testJapanese() throws {
        let document = try FrontmatterDocument(contents: """
---
title: おはよう
---
""")
        XCTAssertEqual(document.title, "おはよう")
    }

}
