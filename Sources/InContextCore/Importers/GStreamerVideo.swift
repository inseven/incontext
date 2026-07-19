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

#if canImport(CGStreamer)

import Foundation

import CGStreamer
import PlatformSupport

final class GStreamerVideo: PlatformVideo {

    private static let genesis: Void = {
        gst_init(nil, nil)
    }()

    private static func scaledSize(_ size: Size?, maxPixelSize: Int) throws -> (width: Int, height: Int) {
        guard let size else {
            throw InContextError.videoLibraryError("Failed to determine video dimensions.")
        }
        let fitted = size.fit(width: maxPixelSize)
        return (fitted.width, fitted.height)
    }

    private static let timeout = GstClockTime(10 * 60 * 1_000_000_000)  // 10 minutes.

    private static func waitFor(bus: UnsafeMutablePointer<GstBus>, type: GstMessageType) throws {
        let types = GstMessageType(type.rawValue | GST_MESSAGE_ERROR.rawValue)
        guard let message = gst_bus_timed_pop_filtered(bus, Self.timeout, types) else {
            throw InContextError.videoLibraryError("Timed out waiting for GStreamer pipeline.")
        }
        defer { gst_message_unref(message) }

        if message.pointee.type == GST_MESSAGE_ERROR {
            var error: UnsafeMutablePointer<GError>?
            var debug: UnsafeMutablePointer<CChar>?
            gst_message_parse_error(message, &error, &debug)
            defer { g_free(debug) }
            throw InContextError.videoLibraryError(Self.message(error))
        }
    }

    private static func message(_ error: UnsafeMutablePointer<GError>?) -> String {
        guard let error else {
            return "Unknown GStreamer error"
        }
        defer { g_error_free(error) }
        return String(cString: error.pointee.message)
    }

    private let fileURL: URL
    private let metadata: AVFormatVideoMetadata

    init(url: URL) async throws {
        _ = GStreamerVideo.genesis
        self.fileURL = url
        self.metadata = try AVFormatVideoMetadata(url: url)
    }

    private var requiresRotation: Bool {
        switch metadata.orientation {
        case .up:
            return false
        case .down, .left, .right:
            return true
        }
    }

    var size: Size? {
        get async throws { metadata.size }
    }

    var duration: Double? {
        get async throws { metadata.duration }
    }

    var creationDate: Date? {
        get async throws { metadata.creationDate }
    }

    var title: String? {
        get async throws { metadata.title }
    }

    var mediaDescription: String? {
        get async throws { metadata.mediaDescription }
    }

    var location: (latitude: Double, longitude: Double)? {
        get async throws { metadata.location }
    }

    func writeThumbnail(at time: Double, maxPixelSize: Int, format: FileType, to url: URL) async throws {

        guard let playbin = gst_element_factory_make("playbin", nil) else {
            throw InContextError.videoLibraryError("Failed to create playbin.")
        }
        defer {
            gst_element_set_state(playbin, GST_STATE_NULL)
            gst_object_unref(playbin)
        }

        guard let uri = g_filename_to_uri(fileURL.path, nil, nil) else {
            throw InContextError.videoLibraryError("Failed to construct URI for '\(fileURL.relativePath)'.")
        }
        defer { g_free(uri) }
        incontext_playbin_set_uri(playbin, uri)

        // Set dummy video and audio sinks to stop output being shown to the user.
        guard let videoSink = gst_element_factory_make("fakesink", nil) else {
            throw InContextError.videoLibraryError("Failed to create fakesink for video.")
        }
        incontext_playbin_set_video_sink(playbin, videoSink)
        guard let audioSink = gst_element_factory_make("fakesink", nil) else {
            throw InContextError.videoLibraryError("Failed to create fakesink for audio.")
        }
        incontext_playbin_set_audio_sink(playbin, audioSink)

        if requiresRotation {
            guard let videoFilter = gst_element_factory_make("videoflip", nil) else {
                throw InContextError.videoLibraryError("Failed to create videoflip filter.")
            }
            incontext_videoflip_set_direction_auto(videoFilter)
            incontext_playbin_set_video_filter(playbin, videoFilter)
        }

        guard let bus = gst_element_get_bus(playbin) else {
            throw InContextError.videoLibraryError("Failed to get pipeline bus.")
        }
        defer { gst_object_unref(bus) }

        guard gst_element_set_state(playbin, GST_STATE_PAUSED) != GST_STATE_CHANGE_FAILURE else {
            throw InContextError.videoLibraryError("Failed to pause pipeline for preroll.")
        }
        try Self.waitFor(bus: bus, type: GST_MESSAGE_ASYNC_DONE)

        let (width, height) = try Self.scaledSize(metadata.size, maxPixelSize: maxPixelSize)

        let seekFlags = GstSeekFlags(GST_SEEK_FLAG_FLUSH.rawValue | GST_SEEK_FLAG_KEY_UNIT.rawValue)
        let position = gint64(time * Double(1_000_000_000))
        guard gst_element_seek_simple(playbin, GST_FORMAT_TIME, seekFlags, position) != 0 else {
            throw InContextError.videoLibraryError("Failed to seek to \(time)s.")
        }
        try Self.waitFor(bus: bus, type: GST_MESSAGE_ASYNC_DONE)

        guard let caps = incontext_jpeg_caps(gint(width), gint(height)) else {
            throw InContextError.videoLibraryError("Failed to construct thumbnail caps.")
        }
        defer { gst_caps_unref(caps) }

        guard let sample = incontext_playbin_convert_sample(playbin, caps) else {
            throw InContextError.videoLibraryError("Failed to extract thumbnail frame.")
        }
        defer { gst_sample_unref(sample) }

        guard let buffer = gst_sample_get_buffer(sample) else {
            throw InContextError.videoLibraryError("Thumbnail sample has no buffer.")
        }

        var map = GstMapInfo()
        guard gst_buffer_map(buffer, &map, GST_MAP_READ) != 0 else {
            throw InContextError.videoLibraryError("Failed to map thumbnail buffer.")
        }
        defer { gst_buffer_unmap(buffer, &map) }

        let data = Data(bytes: map.data, count: Int(map.size))
        try data.write(to: url)
    }

    func writeVideo(maxPixelSize: Int, format: FileType, to url: URL) async throws {
        guard format == .quickTimeMovie else {
            throw InContextError.unsupportedMediaType
        }

        let (width, height) = try Self.scaledSize(metadata.size, maxPixelSize: maxPixelSize)

        guard let uri = g_filename_to_uri(fileURL.path, nil, nil) else {
            throw InContextError.videoLibraryError("Failed to construct URI for '\(fileURL.relativePath)'.")
        }
        defer { g_free(uri) }

        // Video processing pipeline.
        let videoFlip = requiresRotation ? "videoflip video-direction=auto ! " : ""
        let videoBranch = """
        d. ! queue ! \(videoFlip)videoconvert ! videoscale ! videorate ! video/x-raw,width=\(width),height=\(height) ! \
        openh264enc ! h264parse ! queue ! mux.video_0
        """

        // Audio processing pipeline.
        let audioBranch = """
        d. ! queue ! audioconvert ! audioresample ! avenc_aac ! aacparse ! queue ! mux.audio_0
        """

        // Full decode description.
        // Only includes the audio pipeline if the video has an audio stream; without this processing will fail on
        // silent videos.
        let description = """
        uridecodebin uri=\(String(cString: uri)) name=d \
        \(videoBranch) \
        \(metadata.hasAudio ? audioBranch + " " : "")\
        qtmux name=mux ! filesink location=\(url.path)
        """

        var error: UnsafeMutablePointer<GError>?
        guard let pipeline = gst_parse_launch(description, &error) else {
            throw InContextError.videoLibraryError(Self.message(error))
        }
        defer {
            gst_element_set_state(pipeline, GST_STATE_NULL)
            gst_object_unref(pipeline)
        }

        guard let bus = gst_element_get_bus(pipeline) else {
            throw InContextError.videoLibraryError("Failed to get pipeline bus.")
        }
        defer { gst_object_unref(bus) }

        guard gst_element_set_state(pipeline, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE else {
            throw InContextError.videoLibraryError("Failed to start transcode pipeline.")
        }
        try Self.waitFor(bus: bus, type: GST_MESSAGE_EOS)
    }

}

#endif
