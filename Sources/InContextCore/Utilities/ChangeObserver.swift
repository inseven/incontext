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

#if !os(Linux)

import FSEventsWrapper

class ChangeObserver {

    private var iterator: AsyncStream<Void>.AsyncIterator
    let streams: [FSEventStream]

    init(fileURLs: [URL]) throws {
        for fileURL in fileURLs {
            precondition(fileURL.isFileURL)
        }

        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.iterator = stream.makeAsyncIterator()

        self.streams = try fileURLs.map { fileURL in
            let stream = FSEventStream(path: fileURL.path) { stream, event in
                switch event {
                case .itemClonedAtPath:
                    return
                default:
                    continuation.yield()
                }
            }
            guard let stream else {
                throw InContextError.internalInconsistency("Failed to monitor '\(fileURL.path)'.")
            }
            return stream
        }

        streams.forEach { stream in
            stream.startWatching()
        }
    }

    func wait() async {
        _ = await iterator.next()
    }

}

#else

class ChangeObserver {

    private var iterator = AsyncStream<Void> { _ in }.makeAsyncIterator()

    init(fileURLs: [URL]) throws {
    }

    func wait() async {
        _ = await iterator.next()
    }

}

#endif

