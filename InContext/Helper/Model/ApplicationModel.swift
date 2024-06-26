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

import Combine
import ServiceManagement
import SwiftUI

import Sparkle

class ApplicationModel: ObservableObject {

    @Published var sites: [URL: SiteModel] = [:]

    @MainActor var openAtLogin: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update service with error \(error).")
            }
        }
    }

    let settings = Settings()
    var cancellables: [AnyCancellable] = []
    let updaterController = SPUStandardUpdaterController(startingUpdater: false,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)

    init() {
        updaterController.startUpdater()
    }

    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        settings
            .$rootURLs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rootURLs in
                guard let self else {
                    return
                }
                var sites = self.sites
                var rootURLs = Set(rootURLs)

                // Stop and remove existing sites.
                for (rootURL, site) in sites {
                    if !rootURLs.contains(rootURL) {
                        site.stop()
                        sites.removeValue(forKey: rootURL)
                    } else {
                        rootURLs.remove(rootURL)
                    }
                }

                // Create and start new sites.
                for rootURL in rootURLs {
                    let site = SiteModel(rootURL: rootURL)
                    site.start()
                    sites[rootURL] = site
                }

                self.sites = sites
            }
            .store(in: &cancellables)
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        cancellables.removeAll()
    }

    @MainActor func remove(siteModel: SiteModel) {
        dispatchPrecondition(condition: .onQueue(.main))
        settings.rootURLs.removeAll { $0 == siteModel.rootURL }
    }

    @MainActor func quit() {
        dispatchPrecondition(condition: .onQueue(.main))
        stop()
        NSApplication.shared.terminate(nil)
    }

}
