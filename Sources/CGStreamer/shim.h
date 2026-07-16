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

#include <gst/gst.h>

// Lightweight wrappers to work around Swift variadic and macro interop limitations.

static inline void incontext_playbin_set_uri(GstElement *playbin, const gchar *uri) {
    g_object_set(playbin, "uri", uri, NULL);
}

static inline void incontext_playbin_set_video_sink(GstElement *playbin, GstElement *sink) {
    g_object_set(playbin, "video-sink", sink, NULL);
}

static inline void incontext_playbin_set_audio_sink(GstElement *playbin, GstElement *sink) {
    g_object_set(playbin, "audio-sink", sink, NULL);
}

static inline GstSample *incontext_playbin_convert_sample(GstElement *playbin, GstCaps *caps) {
    GstSample *sample = NULL;
    g_signal_emit_by_name(playbin, "convert-sample", caps, &sample);
    return sample;
}

static inline GstCaps *incontext_jpeg_caps(gint width, gint height) {
    return gst_caps_new_simple("image/jpeg",
                                "width", G_TYPE_INT, width,
                                "height", G_TYPE_INT, height,
                                NULL);
}
