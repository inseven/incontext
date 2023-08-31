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

import Combine
import SwiftUI

class ApplicationModel: ObservableObject {

    let settings = Settings()
    var cancellables: [AnyCancellable] = []
    @MainActor @Published var sites: [URL: SiteModel] = [:]

    init() {
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
                Task {
                    var sites = await self.sites
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
                        let site = try await SiteModel(rootURL: rootURL)
                        site.start()
                        sites[rootURL] = site
                    }

                    await MainActor.run { [sites] in
                        self.sites = sites
                    }
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        cancellables.removeAll()
    }

    func remove(siteModel: SiteModel) {
        dispatchPrecondition(condition: .onQueue(.main))
        settings.rootURLs.removeAll { $0 == siteModel.rootURL }
    }

}
