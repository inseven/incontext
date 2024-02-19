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

import Diligence

@main
struct HelperApp: App {

    let applicationModel: ApplicationModel

    init() {
        self.applicationModel = ApplicationModel()
        self.applicationModel.start()
    }

    var body: some Scene {

        MenuBarExtra {
            MainMenu()
                .environmentObject(applicationModel)
        } label: {
#if DEBUG
            Label("InContext Helper", systemImage: "hammer")
#else
            Label("InContext Helper", systemImage: "hammer.fill")
#endif
        }

        LogWindow(applicationModel: applicationModel)

        About(repository: "inseven/incontext", copyright: "Copyright © 2016-2024 Jason Morley") {
            Action("Website", url: URL(string: "https://incontext.app")!)
            Action("GitHub", url: URL(string: "https://github.com/inseven/incontext")!)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
                Credit("Tom Sutcliffe", url: URL(string: "https://github.com/tomsci"))
            }
            Acknowledgements("Thanks") {
                Credit("Lukas Fittl")
                Credit("Sarah Barbour")
            }
        } licenses: {
            License("InContext", author: "Jason Morley", filename: "incontext-license")
            License("Tilt", author: "Tom Sutcliffe", filename: "tilt-license")
        }
        .handlesExternalEvents(matching: [.aboutURL])

    }
    
}
