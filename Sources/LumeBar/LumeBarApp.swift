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

    private var menuBarStatusImage: NSImage {
        if let url = Bundle.module.url(
            forResource: "menubar-2x",
            withExtension: "png",
            subdirectory: "Assets.xcassets/MenubarIcon.imageset"
        ), let image = NSImage(contentsOf: url) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            return image
        }

        let fallback = NSImage(
            systemSymbolName: "play.rectangle.on.rectangle",
            accessibilityDescription: "Lume"
        ) ?? NSImage()
        fallback.size = NSSize(width: 18, height: 18)
        fallback.isTemplate = true
        return fallback
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
                Image(nsImage: menuBarStatusImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(baseURL: $baseURL, noDisplay: $noDisplay)
        }
    }
}
