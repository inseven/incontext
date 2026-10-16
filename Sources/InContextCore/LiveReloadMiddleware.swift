// MIT License
//
// Copyright (c) 2026 Jason Morley
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

// Initially generated using AI (Claude Opus 5.5).

import Foundation

import Hummingbird

struct LiveReloadMiddleware<Context: RequestContext>: RouterMiddleware {

    private final class Collector: @unchecked Sendable {
        var buffer = ByteBuffer()
    }

    private struct CollectingWriter: ResponseBodyWriter {

        let collector: Collector

        mutating func write(_ buffer: ByteBuffer) async throws {
            var buffer = buffer
            collector.buffer.writeBuffer(&buffer)
        }

        consuming func finish(_ trailingHeaders: HTTPFields?) async throws {
        }

    }

    static func script(eTag: String) -> String {
        let data = try! JSONEncoder().encode(eTag)
        let eTagLiteral = String(decoding: data, as: UTF8.self)
        return """
<script>
(function() {
    const eTag = \(eTagLiteral);
    function check() {
        fetch(window.location.href, {method: "HEAD", cache: "no-store"})
            .then(function(response) {
                if (response.ok && response.headers.get("ETag") != eTag) {
                    window.location.reload();
                    return;
                }
                setTimeout(check, 1000);
            })
            .catch(function() {
                setTimeout(check, 1000);
            });
    }
    setTimeout(check, 1000);
})();
</script>
"""
    }

    static func inject(script: String, into html: String) -> String {
        guard let range = html.range(of: "</body>", options: [.caseInsensitive, .backwards]) else {
            return html + script
        }
        var html = html
        html.insert(contentsOf: script, at: range.lowerBound)
        return html
    }

    func handle(_ request: Request,
                context: Context,
                next: (Request, Context) async throws -> Response) async throws -> Response {
        var response = try await next(request, context)
        guard response.status == .ok,
              let contentType = response.headers[.contentType],
              contentType.lowercased().hasPrefix("text/html"),
              let eTag = response.headers[.eTag]
        else {
            return response
        }

        let script = Self.script(eTag: eTag)

        // Injected content invalidates byte ranges into the original file.
        response.headers[.acceptRanges] = nil

        switch request.method {
        case .get:
            let collector = Collector()
            try await response.body.write(CollectingWriter(collector: collector))
            let html = Self.inject(script: script, into: String(buffer: collector.buffer))
            let buffer = ByteBuffer(string: html)
            response.headers[.contentLength] = String(buffer.readableBytes)
            response.body = ResponseBody(byteBuffer: buffer)
        case .head:
            // Update the content length header.
            if let contentLength = response.headers[.contentLength].flatMap(Int.init) {
                response.headers[.contentLength] = String(contentLength + script.utf8.count)
            }
        default:
            break
        }
        return response
    }

}
