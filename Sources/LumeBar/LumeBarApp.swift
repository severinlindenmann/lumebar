import AppKit
import SwiftUI

@main
struct LumeBarApp: App {
    @AppStorage("lume.baseURL") private var baseURL = "http://localhost:7777"
    @AppStorage("lume.noDisplay") private var noDisplay = true
    @StateObject private var client = LumeClient()
    @StateObject private var thumbnails = VNCThumbnailStore()

    init() {
        // Run as a menu bar only app (no Dock icon).
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(client: client, thumbnails: thumbnails, noDisplay: $noDisplay)
                .frame(width: 440)
                .onAppear { client.updateBaseURL(baseURL) }
                .onChange(of: baseURL) {
                    client.updateBaseURL(baseURL)
                }
        } label: {
            Label {
                Text("Lume")
            } icon: {
                Image("MenubarIcon", bundle: .module)
                    .renderingMode(.template)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(baseURL: $baseURL, noDisplay: $noDisplay)
        }
    }
}
