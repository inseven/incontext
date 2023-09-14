// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
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

struct SiteMenu: View {

    @ObservedObject var applicationModel: ApplicationModel
    @ObservedObject var siteModel: SiteModel

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            Button("Open") {
                siteModel.open()
            }
            Button("Preview") {
                siteModel.preview()
            }
        }
        Divider()
        ActionsMenu(siteModel: siteModel)
        FavoritesMenu(siteModel: siteModel)
        Divider()
        Button("Logs...") {
            openWindow(id: LogWindow.windowID, value: siteModel.rootURL)
        }
        Divider()
        Button {
            NSWorkspace.shared.open(siteModel.rootURL)
        } label: {
            Text("Show in Finder")
        }
        Divider()
        Button {
            applicationModel.remove(siteModel: siteModel)
        } label: {
            Text("Remove")
        }
    }

}

struct ActionsMenu: View {

    @ObservedObject var siteModel: SiteModel

    var body: some View {
        Menu {
            ForEach(siteModel.actions) { action in
                Button {
                    siteModel.run(action)
                } label: {
                    Text(action.name)
                }
            }
        } label: {
            Text("Actions")
        }
    }

}


struct FavoritesMenu: View {

    @ObservedObject var siteModel: SiteModel

    var body: some View {
        Menu {
            ForEach(siteModel.favorites) { favorite in
                Button(favorite.title) {
                    NSWorkspace.shared.open(favorite.rootURL)
                }
            }
        } label: {
            Text("Favorites")
        }
    }

}
