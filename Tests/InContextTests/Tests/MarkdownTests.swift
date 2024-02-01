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

class MarkdownTests: XCTestCase {

    func testPlain() {
        XCTAssertEqual("cheese".html(), "<p>cheese</p>\n")
    }

    func testMultipleParagraphs() {
        XCTAssertEqual("""
Paragraph one
comprises two lines.

Paragraph two is a single line.
""".html(), "<p>Paragraph one\ncomprises two lines.</p>\n\n<p>Paragraph two is a single line.</p>\n")
    }

    func testFootnotes() {
        XCTAssertEqual("""
Text with footnote[^1].

[^1]: No, really. This is a footnote.
""".html(), """
<p>Text with footnote<sup id="fnref1"><a href="#fn1" rel="footnote">1</a></sup>.</p>

<div class="footnotes">
<hr>
<ol>

<li id="fn1">
<p>No, really. This is a footnote.&nbsp;<a href="#fnref1" rev="footnote">&#8617;</a></p>
</li>

</ol>
</div>

""")
    }

    func testHeaderAnchors() {
        XCTAssertEqual("""
# Header 1
""".html(), """
<h1><a id="header-1"></a>Header 1</h1>

""")

        XCTAssertEqual("""
# Header 1

## Header 2
""".html(), """
<h1><a id="header-1"></a>Header 1</h1>

<h2><a id="header-2"></a>Header 2</h2>

""")
    }

}
