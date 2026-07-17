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

    private let stream: AsyncStream<Void>
    let streams: [FSEventStream]

    init(fileURLs: [URL]) throws {
        for fileURL in fileURLs {
            precondition(fileURL.isFileURL)
        }

        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.stream = stream

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

    func wait() async throws {
        for await _ in stream {
            break
        }
    }

}

#else

import Glibc

class ChangeObserver {

    private class Monitor {

        static let eventMask = UInt32(IN_CREATE | IN_DELETE | IN_MODIFY | IN_MOVED_FROM | IN_MOVED_TO |
                                      IN_CLOSE_WRITE | IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF)

        private let inotifyDescriptor: Int32
        private let shutdownDescriptor: Int32
        private let continuation: AsyncThrowingStream<Void, Error>.Continuation
        private var watchedDirectories: [Int32: String] = [:]

        init(rootURLs: [URL], shutdownDescriptor: Int32, continuation: AsyncThrowingStream<Void, Error>.Continuation) throws {
            self.inotifyDescriptor = inotify_init1(Int32(IN_CLOEXEC))
            self.shutdownDescriptor = shutdownDescriptor
            self.continuation = continuation
            guard inotifyDescriptor >= 0 else {
                throw InContextError.internalInconsistency("Failed to initialize inotify.")
            }
            do {
                for rootURL in rootURLs {
                    try watch(path: rootURL.path, isRequired: true)
                }
            } catch {
                close(inotifyDescriptor)
                throw error
            }
        }

        private func watch(path: String, isRequired: Bool) throws {
            let descriptor = inotify_add_watch(inotifyDescriptor, path, Self.eventMask)
            guard descriptor >= 0 else {
                let failure = errno
                if failure == ENOSPC {
                    throw InContextError.inotifyWatchLimitReached(path)
                }
                if isRequired {
                    throw InContextError.internalInconsistency("Failed to monitor '\(path)'.")
                }
                return
            }
            watchedDirectories[descriptor] = path
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: path) else {
                return
            }
            for entry in entries {
                let entryPath = path + "/" + entry
                var status = stat()
                guard lstat(entryPath, &status) == 0, (status.st_mode & S_IFMT) == S_IFDIR else {
                    continue
                }
                try watch(path: entryPath, isRequired: false)
            }
        }

        func run() {
            defer {
                close(inotifyDescriptor)
                close(shutdownDescriptor)
                continuation.finish()
            }

            let bufferSize = 65536
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            while true {
                var descriptors = [
                    pollfd(fd: inotifyDescriptor, events: Int16(POLLIN), revents: 0),
                    pollfd(fd: shutdownDescriptor, events: Int16(POLLIN), revents: 0),
                ]
                guard poll(&descriptors, 2, -1) >= 0 || errno == EINTR else {
                    return
                }
                if descriptors[1].revents != 0 {
                    return
                }
                guard descriptors[0].revents != 0 else {
                    continue
                }

                let count = read(inotifyDescriptor, &buffer, bufferSize)
                guard count > 0 else {
                    return
                }

                var offset = 0
                let headerSize = MemoryLayout<inotify_event>.size
                while offset + headerSize <= count {
                    var event = inotify_event()
                    withUnsafeMutableBytes(of: &event) { destination in
                        buffer.withUnsafeBytes { source in
                            destination.copyMemory(from: UnsafeRawBufferPointer(rebasing: source[offset..<offset + headerSize]))
                        }
                    }

                    // Check for event queue overflow.
                    if (event.mask & UInt32(IN_Q_OVERFLOW)) != 0 {
                        continuation.finish(throwing: InContextError.inotifyEventQueueOverflow)
                        return
                    }

                    // Register new directories.
                    if event.wd >= 0,
                       (event.mask & UInt32(IN_ISDIR)) != 0,
                       (event.mask & UInt32(IN_CREATE | IN_MOVED_TO)) != 0,
                       event.len > 0,
                       let parent = watchedDirectories[event.wd] {
                        let name = buffer[(offset + headerSize)...].withUnsafeBufferPointer { pointer in
                            String(cString: pointer.baseAddress!)
                        }
                        do {
                            try watch(path: parent + "/" + name, isRequired: false)
                        } catch {
                            continuation.finish(throwing: error)
                            return
                        }
                    }

                    offset += headerSize + Int(event.len)
                }

                continuation.yield()
            }
        }

    }

    private let stream: AsyncThrowingStream<Void, Error>
    private let shutdownDescriptor: Int32

    init(fileURLs: [URL]) throws {
        for fileURL in fileURLs {
            precondition(fileURL.isFileURL)
        }

        let (stream, continuation) = AsyncThrowingStream<Void, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.stream = stream

        var pipeDescriptors: [Int32] = [0, 0]
        guard pipe(&pipeDescriptors) == 0 else {
            throw InContextError.internalInconsistency("Failed to create shutdown pipe.")
        }
        self.shutdownDescriptor = pipeDescriptors[1]

        let monitor: Monitor
        do {
            monitor = try Monitor(rootURLs: fileURLs,
                                  shutdownDescriptor: pipeDescriptors[0],
                                  continuation: continuation)
        } catch {
            close(pipeDescriptors[0])
            close(pipeDescriptors[1])
            throw error
        }
        let thread = Thread {
            monitor.run()
        }
        thread.name = "change-observer"
        thread.start()
    }

    deinit {
        var byte: UInt8 = 0
        _ = write(shutdownDescriptor, &byte, 1)
        close(shutdownDescriptor)
    }

    func wait() async throws {
        for try await _ in stream {
            break
        }
    }

}

#endif

