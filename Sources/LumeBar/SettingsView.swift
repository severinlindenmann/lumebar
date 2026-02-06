import SwiftUI

struct SettingsView: View {
    @Binding var baseURL: String
    @Binding var noDisplay: Bool

    var body: some View {
        Form {
            Section("Lume Service") {
                TextField("Base URL", text: $baseURL)
                Text("Default is http://localhost:7777")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Run Options") {
                Toggle("Start headless", isOn: $noDisplay)
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}
