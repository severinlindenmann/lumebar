import AppKit
import Foundation
import RoyalVNCKit

@MainActor
final class VNCThumbnailStore: ObservableObject {
    @Published private(set) var images: [String: CGImage] = [:]
    @Published private(set) var statuses: [String: String] = [:]

    private var connections: [String: ThumbnailConnection] = [:]
    private var connectionUrls: [String: String] = [:]
    private var snapshotSessionID = UUID()
    private var snapshottedVMs: Set<String> = []

    func beginSnapshotSession() {
        snapshotSessionID = UUID()
        snapshottedVMs.removeAll()
    }

    func start(vmName: String, vncUrl: String) {
        let currentSession = snapshotSessionID
        if snapshottedVMs.contains(vmName) {
            return
        }
        if let existing = connectionUrls[vmName], existing == vncUrl {
            return
        }
        if connections[vmName] != nil {
            stop(vmName: vmName)
        }
        guard let info = VNCConnectionInfo(vncUrl: vncUrl) else {
            statuses[vmName] = "Invalid VNC URL"
            images.removeValue(forKey: vmName)
            return
        }

        snapshottedVMs.insert(vmName)

        let logger = VNCCustomLogger(logDebugHandler: { _ in },
                                     logInfoHandler: { _ in },
                                     logWarningHandler: { _ in },
                                     logErrorHandler: { _ in })

        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false,
                                              hostname: info.host,
                                              port: UInt16(info.port),
                                              isShared: true,
                                              isScalingEnabled: true,
                                              useDisplayLink: false,
                                              // Allow the connection to send basic keyboard input (used for wake events).
                                              // This does not require Accessibility permissions.
                                              inputMode: .forwardKeyboardShortcutsIfNotInUseLocally,
                                              isClipboardRedirectionEnabled: false,
                                              colorDepth: .depth24Bit,
                                              frameEncodings: .default)

        let connection = VNCConnection(settings: settings, logger: logger)
        let delegate = ThumbnailConnection(vmName: vmName,
                                           credential: info.credential,
                                           connection: connection,
                                           stopAfterFirstFrame: true,
                                           onImage: { [weak self] image in
                                               Task { @MainActor in
                                                   self?.images[vmName] = image
                                               }
                                           },
                                           onStatus: { [weak self] status in
                                               Task { @MainActor in
                                                   self?.statuses[vmName] = status
                                               }
                                           },
                                           onComplete: { [weak self] in
                                               Task { @MainActor in
                                                   guard let self else { return }
                                                   // Only tear down if we're still in the same session.
                                                   guard self.snapshotSessionID == currentSession else { return }
                                                   self.connections.removeValue(forKey: vmName)
                                                   self.connectionUrls.removeValue(forKey: vmName)
                                               }
                                           })

        connections[vmName] = delegate
        connectionUrls[vmName] = vncUrl
        statuses[vmName] = "Snapshotting…"
        delegate.connect()
    }

    func stop(vmName: String) {
        stop(vmName: vmName, clearImage: true)
    }

    func stop(vmName: String, clearImage: Bool) {
        guard let delegate = connections.removeValue(forKey: vmName) else { return }
        delegate.disconnect()
        statuses.removeValue(forKey: vmName)
        if clearImage {
            images.removeValue(forKey: vmName)
        }
        connectionUrls.removeValue(forKey: vmName)
    }

    func stopAll(keepImages: Bool = true) {
        let vmNames = Array(connections.keys)
        for vmName in vmNames {
            stop(vmName: vmName, clearImage: !keepImages)
        }
    }

    func image(for vmName: String) -> CGImage? {
        images[vmName]
    }

    func status(for vmName: String) -> String? {
        statuses[vmName]
    }
}

private final class ThumbnailConnection: NSObject, VNCConnectionDelegate {
    private let vmName: String
    private let credential: VNCCredential?
    private let onImage: @Sendable (CGImage) -> Void
    private let onStatus: (String) -> Void
    private let connection: VNCConnection
    private let stopAfterFirstFrame: Bool
    private let onComplete: @Sendable () -> Void

    private var lastUpdate = Date.distantPast
    private let minUpdateInterval: TimeInterval = 2.0
    private var lastFramebufferSize: (width: UInt16, height: UInt16)?
    private var didSendWakeInput = false
    private var didCaptureFrame = false

    init(vmName: String,
         credential: VNCCredential?,
         connection: VNCConnection,
         stopAfterFirstFrame: Bool,
         onImage: @escaping @Sendable (CGImage) -> Void,
         onStatus: @escaping (String) -> Void,
         onComplete: @escaping @Sendable () -> Void) {
        self.vmName = vmName
        self.credential = credential
        self.onImage = onImage
        self.onStatus = onStatus
        self.connection = connection
        self.stopAfterFirstFrame = stopAfterFirstFrame
        self.onComplete = onComplete
        super.init()
        self.connection.delegate = self
    }

    func connect() {
        connection.connect()
    }

    func disconnect() {
        connection.disconnect()
        connection.delegate = nil
    }

    func connection(_ connection: VNCConnection,
                    stateDidChange connectionState: VNCConnection.ConnectionState) {
        switch connectionState.status {
        case .connecting:
            onStatus("Connecting")
        case .connected:
            onStatus("Live")
            wakeDisplayIfNeeded(connection: connection)
        case .disconnecting:
            onStatus("Disconnecting")
        case .disconnected:
            if let error = connectionState.error as? VNCError,
               error.shouldDisplayToUser {
                let description = error.errorDescription ?? "Unknown error"
                onStatus("Error: \(description)")
            } else {
                onStatus("Disconnected")
            }
        }
    }

    func connection(_ connection: VNCConnection,
                    credentialFor authenticationType: VNCAuthenticationType,
                    completion: @escaping (VNCCredential?) -> Void) {
        completion(credential)
    }

    func connection(_ connection: VNCConnection,
                    didCreateFramebuffer framebuffer: VNCFramebuffer) {
        onStatus("Live")
        updateFramebufferSize(framebuffer)
    }

    func connection(_ connection: VNCConnection,
                    didResizeFramebuffer framebuffer: VNCFramebuffer) {
        onStatus("Live")
        updateFramebufferSize(framebuffer)
    }

    func connection(_ connection: VNCConnection,
                    didUpdateCursor cursor: VNCCursor) {
        // No-op; thumbnails ignore cursor updates.
    }

    func connection(_ connection: VNCConnection,
                    didUpdateFramebuffer framebuffer: VNCFramebuffer,
                    x: UInt16, y: UInt16,
                    width: UInt16, height: UInt16) {
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= minUpdateInterval else { return }
        lastUpdate = now

        guard !didCaptureFrame else { return }
        guard let cgImage = framebuffer.cgImage else { return }
        onImage(cgImage)

        if stopAfterFirstFrame {
            didCaptureFrame = true
            disconnect()
            onComplete()
        }
    }

    private func updateFramebufferSize(_ framebuffer: VNCFramebuffer) {
        lastFramebufferSize = (width: framebuffer.size.width, height: framebuffer.size.height)
    }

    private func wakeDisplayIfNeeded(connection: VNCConnection) {
        guard !didSendWakeInput else { return }
        didSendWakeInput = true

        let size = lastFramebufferSize ?? {
            if let framebuffer = connection.framebuffer {
                return (width: framebuffer.size.width, height: framebuffer.size.height)
            }
            return nil
        }()

        guard let size else { return }
        let width = size.width
        let height = size.height
        guard width > 2, height > 2 else { return }

        // Some guests show a black framebuffer until *any* input is sent (Screen Sharing behaves similarly).
        // Try a small mouse move + a single click to wake the display.
        let x = max(UInt16(2), min(width - 3, width / 2))
        let y = max(UInt16(2), min(height - 3, height / 2))

        connection.mouseMove(x: x, y: y)
        connection.mouseButtonDown(.left, x: x, y: y)
        connection.mouseButtonUp(.left, x: x, y: y)

        // Follow up with a harmless modifier tap as a fallback.
        connection.keyDown(.shift)
        connection.keyUp(.shift)
    }
}

private struct VNCConnectionInfo {
    let host: String
    let port: Int
    let credential: VNCCredential?

    init?(vncUrl: String) {
        guard let components = URLComponents(string: vncUrl),
              components.scheme?.lowercased() == "vnc",
              let host = components.host else {
            return nil
        }

        self.host = host
        self.port = components.port ?? 5900

        let username = components.user
        let password = components.password

        if let password, !password.isEmpty {
            if let username, !username.isEmpty {
                credential = VNCUsernamePasswordCredential(username: username,
                                                           password: password)
            } else {
                credential = VNCPasswordCredential(password: password)
            }
        } else {
            credential = nil
        }
    }
}
