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

extension Event.Level {

    var color: Color {
        switch self {
        case .debug:
            return .primary
        case .info:
            return .primary
        case .notice:
            return .primary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

}

@main
struct HelperApp: App {

    let applicationModel: ApplicationModel

    init() {
        self.applicationModel = ApplicationModel()
        self.applicationModel.start()
    }

    var body: some Scene {

        MenuBarExtra {
            SiteList(applicationModel: applicationModel)
            Divider()
            Menu {
                SettingsMenu(applicationModel: applicationModel)
            } label: {
                Text("Settings")
            }
            Divider()
            Menu {
                Menu {
                    Button("Copy x-location") {
                        Task {
                            do {
                                let pasteboard = NSPasteboard.general
                                guard let address = pasteboard.string(forType: .string) else {
                                    return
                                }
                                let location = try await Geocoder.xLocation(for: address)
                                pasteboard.clearContents()
                                pasteboard.setString(location, forType: .string)
                            } catch {
                                print("Failed to geocode address with error \(error).")
                            }
                        }
                    }
                } label: {
                    Text("Location")
                }
            } label: {
                Text("Utilities")
            }

            Divider()

            Button {
                applicationModel.quit()
            } label: {
                Text("Quit")
            }

        } label: {
            Text("🦫")
        }

        LogWindow(applicationModel: applicationModel)

    }

    
}
