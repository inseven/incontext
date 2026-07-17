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

#if canImport(CAVFormat)

import Foundation

import CAVFormat

final class AVFormatVideoMetadata {

    private static func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private var formatContext: UnsafeMutablePointer<AVFormatContext>?

    init(url: URL) throws {
        var context: UnsafeMutablePointer<AVFormatContext>? = nil
        guard avformat_open_input(&context, url.path, nil, nil) == 0 else {
            throw InContextError.videoLibraryError("Failed to open video file '\(url.relativePath)'.")
        }
        guard avformat_find_stream_info(context, nil) >= 0 else {
            avformat_close_input(&context)
            throw InContextError.videoLibraryError("Failed to read stream information for '\(url.relativePath)'.")
        }
        self.formatContext = context
    }

    deinit {
        avformat_close_input(&formatContext)
    }

    private func firstCodecParameters(type: AVMediaType) -> UnsafeMutablePointer<AVCodecParameters>? {
        guard let formatContext, let streams = formatContext.pointee.streams else {
            return nil
        }
        for i in 0..<Int(formatContext.pointee.nb_streams) {
            guard let stream = streams[i],
                  let codecpar = stream.pointee.codecpar
            else {
                continue
            }
            if codecpar.pointee.codec_type == type {
                return codecpar
            }
        }
        return nil
    }

    private var videoCodecParameters: UnsafeMutablePointer<AVCodecParameters>? {
        firstCodecParameters(type: AVMEDIA_TYPE_VIDEO)
    }

    var hasAudio: Bool {
        firstCodecParameters(type: AVMEDIA_TYPE_AUDIO) != nil
    }

    var size: Size? {
        guard let codecpar = videoCodecParameters else {
            return nil
        }
        return Size(width: Int(codecpar.pointee.width), height: Int(codecpar.pointee.height))
    }

    var duration: Double? {
        guard let formatContext, formatContext.pointee.duration > 0 else {
            return nil
        }
        return Double(formatContext.pointee.duration) / Double(AV_TIME_BASE)
    }

    var title: String? {
        tag("title")
    }

    var mediaDescription: String? {
        tag("com.apple.quicktime.description")
    }

    var creationDate: Date? {
        if let value = tag("com.apple.quicktime.creationdate"), let date = Self.parseDate(value) {
            return date
        }
        if let value = tag("creation_time"), let date = Self.parseDate(value) {
            return date
        }
        return nil
    }

    lazy var location: (latitude: Double, longitude: Double)? = {
        guard let value = tag("com.apple.quicktime.location.ISO6709") else {
            return nil
        }
        return ISO6709.parse(value)
    }()

    private func tag(_ key: String) -> String? {
        guard let formatContext,
              let entry = av_dict_get(formatContext.pointee.metadata, key, nil, 0),
              let value = entry.pointee.value
        else {
            return nil
        }
        return String(cString: value)
    }

}

#endif
