import SwiftUI

struct ContentView: View {
    @ObservedObject var client: LumeClient
    @ObservedObject var thumbnails: VNCThumbnailStore
    @Binding var noDisplay: Bool

    @State private var pollingTask: Task<Void, Never>?

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 10) {
                header

                if let error = client.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                VStack(spacing: 10) {
                    if client.vms.isEmpty && !client.isLoading {
                        Text("No VMs found")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(client.vms) { vm in
                            VMRow(vm: vm, client: client, thumbnails: thumbnails, noDisplay: $noDisplay)
                        }
                    }
                }
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)

                Divider()

                HStack {
                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                    .keyboardShortcut("q")
                    .controlSize(.small)

                    Spacer()

                    settingsButton
                }
            }
            .padding(12)
            .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onAppear {
            thumbnails.beginSnapshotSession()
            startPolling()
        }
        .onDisappear {
            pollingTask?.cancel()
            pollingTask = nil
            thumbnails.stopAll(keepImages: true)
        }
    }

    private var header: some View {
        HStack {
            Text("Lume VMs")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsLink()
                .controlSize(.small)
        } else {
            Button("Settings") {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            .controlSize(.small)
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            await client.fetchVms()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if Task.isCancelled { break }
                if !client.isLoading {
                    await client.fetchVms()
                }
            }
        }
    }
}

private struct VMRow: View {
    let vm: LumeVM
    @ObservedObject var client: LumeClient
    @ObservedObject var thumbnails: VNCThumbnailStore
    @Binding var noDisplay: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(vm.stateDescription)
                        .font(.caption)
                        .foregroundStyle(vm.isRunning ? .green : .secondary)
                }

                Spacer()

                if vm.isRunning {
                    ScreenSharingButton(vm: vm, client: client)
                }

                if vm.isRunning {
                    Button("Stop") {
                        Task { await client.stop(vm: vm) }
                    }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                    .disabled(client.isActionInFlight(vmName: vm.name))
                } else {
                    Button("Start") {
                        Task { await client.run(vm: vm, noDisplay: noDisplay) }
                    }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                    .disabled(client.isActionInFlight(vmName: vm.name))
                }
            }

            if vm.isRunning {
                DetailsView(vm: vm, client: client, thumbnails: thumbnails)
                    .padding(.top, 8)
            }
        }
        .padding(8)
        .modifier(GlassCard(cornerRadius: 10))
        .task(id: "\(vm.name)-\(vm.isRunning)") {
            if vm.isRunning {
                await client.fetchDetails(for: vm)
            }
        }
        .task(id: "\(vm.name)-\(vm.isRunning)-\(vm.vncUrl ?? "")") {
            if vm.isRunning, let vncUrl = vm.vncUrl {
                thumbnails.start(vmName: vm.name, vncUrl: vncUrl)
            } else {
                thumbnails.stop(vmName: vm.name)
            }
        }
    }
}

private struct DetailsView: View {
    let vm: LumeVM
    @ObservedObject var client: LumeClient
    @ObservedObject var thumbnails: VNCThumbnailStore
    @State private var isStatsExpanded = false
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .binary
        return formatter
    }()

    var body: some View {
        let rows = rowsForDetails()

        VStack(alignment: .leading, spacing: 8) {
            thumbnailView

            if let error = client.detailsError[vm.name] {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }

            if hasExtraDetails(rows) {
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        isStatsExpanded.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .rotationEffect(.degrees(isStatsExpanded ? 90 : 0))
                                .animation(.snappy(duration: 0.18), value: isStatsExpanded)
                            Text("Details")
                                .font(.footnote.weight(.semibold))
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)

                    if isStatsExpanded {
                        detailRows(rows)
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(value ?? "—")
                .font(.footnote)
        }
    }

    private var thumbnailView: some View {
        let image = thumbnails.image(for: vm.name)
        let aspect: CGFloat = 3 / 2
        let minHeight: CGFloat = image == nil ? 120 : 0
        let maxHeight: CGFloat = 300
        let vncUrl = client.details[vm.name]?.vncUrl ?? vm.vncUrl
        let ip = client.details[vm.name]?.ipAddress ?? vm.ipAddress
        let isScreenSharingReady = (vncUrl?.isEmpty == false) || (ip?.isEmpty == false)

        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.clear)

            if let image {
                Image(decorative: image, scale: 1, orientation: .up)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if let status = thumbnails.status(for: vm.name) {
                Text(status)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("Waiting for video…")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(aspect, contentMode: .fit)
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .glassEffect(in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard isScreenSharingReady else { return }
            Task { await client.openScreenSharing(vm: vm) }
        }
        .help(isScreenSharingReady ? "Double-click to open Screen Sharing" : "Waiting for VNC details")
    }

    @ViewBuilder
    private func detailRows(_ rows: [(String, String?)]) -> some View {
        ForEach(rows, id: \.0) { row in
            if let value = sanitized(row.1) {
                detailRow(row.0, value)
            }
        }
    }

    private func sanitized(_ value: String?) -> String? {
        guard var value else { return nil }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value == "—" { return nil }
        return value
    }

    private func rowsForDetails() -> [(String, String?)] {
        if let details = client.details[vm.name] {
            return [
                ("Status", details.stateDescription),
                ("IP", details.ipAddress),
                ("CPU", formatCount(details.cpuCount)),
                ("Memory", formatBytes(details.memorySize)),
                ("Disk", formatDisk(details.diskSize)),
                ("OS", details.os),
                ("Storage", details.storage),
                ("Display", details.display),
                ("Created", details.createdAt)
            ]
        }

        return [
            ("Status", vm.stateDescription),
            ("CPU", formatCount(vm.cpuCount)),
            ("Memory", formatBytes(vm.memorySize)),
            ("Disk", formatDisk(vm.diskSize)),
            ("OS", vm.os)
        ]
    }

    private func hasExtraDetails(_ rows: [(String, String?)]) -> Bool {
        let filtered = rows.compactMap { row -> (String, String)? in
            guard let value = sanitized(row.1) else { return nil }
            return (row.0, value)
        }
        return filtered.contains { !["Status", "OS"].contains($0.0) }
    }

    private func formatBytes(_ bytes: Int64?) -> String? {
        guard let bytes else { return nil }
        return Self.byteFormatter.string(fromByteCount: bytes)
    }

    private func formatDisk(_ disk: DiskSize?) -> String? {
        guard let disk else { return nil }
        let total = formatBytes(disk.total)
        let allocated = formatBytes(disk.allocated)
        if let total, let allocated {
            return "\(total) (allocated \(allocated))"
        }
        return total ?? allocated
    }

    private func formatCount(_ value: Int?) -> String? {
        guard let value else { return nil }
        return "\(value)"
    }
}

private struct GlassCard: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct ScreenSharingButton: View {
    let vm: LumeVM
    @ObservedObject var client: LumeClient

    var body: some View {
        let vncUrl = client.details[vm.name]?.vncUrl ?? vm.vncUrl
        let ip = client.details[vm.name]?.ipAddress ?? vm.ipAddress
        let isReady = (vncUrl?.isEmpty == false) || (ip?.isEmpty == false)

        return Button("Screen Sharing") {
            Task { await client.openScreenSharing(vm: vm) }
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .disabled(!isReady)
        .help(isReady ? "Open Screen Sharing" : "Waiting for VNC details")
    }
}
