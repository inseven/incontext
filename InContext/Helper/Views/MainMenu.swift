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

import SwiftUI

import Glitter

struct MainMenu: View {

    @EnvironmentObject var applicationModel: ApplicationModel

    @Environment(\.openURL) var openURL

    var body: some View {
        SiteList(applicationModel: applicationModel)

        Divider()

        Button("Add Site...", systemImage: "folder.badge.plus") {
            print("Add Site")
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            guard openPanel.runModal() ==  NSApplication.ModalResponse.OK,
                  let url = openPanel.url else {
                return
            }
            applicationModel.settings.rootURLs.append(url)
        }

        Divider()

        Button("About...", systemImage: "info.circle") {
            openURL(.about)
        }

        Menu("Settings", systemImage: "gear") {
            SettingsMenu(applicationModel: applicationModel)
        }

        Menu("Help", systemImage: "questionmark.circle") {

            Button("Website", systemImage: "globe") {
                openURL(.website)
            }

            Button("Privacy Policy", systemImage: "globe") {
                openURL(.privacyPolicy)
            }

            Button("GitHub", systemImage: "globe") {
                openURL(.gitHub)
            }

            Button("Support", systemImage: "envelope") {
                openURL(URL(address: "support@jbmorley.co.uk", subject: HelperApp.supportTitle)!)
            }

            Divider()

            Button("Donate", systemImage: "globe") {
                openURL(.donate)
            }

            Button {
                openURL(URL(string: "https://jbmorley.co.uk/software")!)
            } label: {
                Label("More Software by Jason Morley", systemImage: "globe")
            }

        }

        Divider()

        UpdateLink(updater: applicationModel.updaterController.updater)

        Divider()

        Button("Quit", systemImage: "xmark.rectangle") {
            applicationModel.quit()
        }
    }

}
