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

import SwiftUI

struct SessionRow: View {

    @ObservedObject var session: HelperSession

    var body: some View {
        Label {
            HStack {
                Text(session.name)
                Text(session.startDate.formatted())
                    .foregroundStyle(.secondary)
                Spacer()
                switch session.state {
                case .running:
                    ProgressView()
                        .controlSize(.small)
                case .success:
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                case .failure:
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.red)
                }
            }
        } icon: {
            switch session.type {
            case .build:
                Image(systemName: "hammer")
                    .foregroundStyle(.primary)
            case .action:
                Image(systemName: "play")
                    .foregroundStyle(.primary)
            }
        }
    }

}

struct LogView: View {

    @ObservedObject var siteModel: SiteModel
    @ObservedObject var helperTracker: HelperTracker

    @State var selection: HelperSession.ID? = nil

    init(siteModel: SiteModel) {
        self.siteModel = siteModel
        self.helperTracker = siteModel.tracker
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(helperTracker.sessions) { session in
                    SessionRow(session: session)
                }
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if let session = helperTracker.sessions.first(where: { $0.id == selection }) {
                SessionView(session: session)
            } else {
                ContentUnavailableView("No Log Selected", systemImage: "list.bullet.rectangle")
            }
        }
        .navigationTitle(siteModel.title)
        .navigationSubtitle(siteModel.url.absoluteString)
        .toolbar {

            ToolbarItem {
                Button {
                    siteModel.open()
                } label: {
                    Label("Open", systemImage: "globe")
                }
            }

            ToolbarItem {
                Button {
                    siteModel.preview()
                } label: {
                    Label("Preview", systemImage: "eye.circle")
                }
            }

        }
    }

}
