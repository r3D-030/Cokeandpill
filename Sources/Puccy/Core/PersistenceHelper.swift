import Foundation
import UIKit

// MARK: - Persistence Helper
// Keeps Puccy alive in the rootless environment by registering
// a LaunchDaemon or using the jailbreak's own persistence mechanism.

final class PersistenceHelper {

    static let shared = PersistenceHelper()
    private init() {}

    enum PersistenceMethod: String, CaseIterable {
        case launchDaemon = "LaunchDaemon"
        case launchAgent  = "LaunchAgent"
        case none         = "None"
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: daemonPlistPath)
    }

    private var daemonPlistPath: String {
        RootlessHelper.path("/Library/LaunchDaemons/com.puccy.persistence.plist")
    }

    // ── Install persistence ───────────────────────────────────────────────
    func install(method: PersistenceMethod = .launchDaemon) -> Bool {
        switch method {
        case .launchDaemon: return installLaunchDaemon()
        case .launchAgent:  return installLaunchAgent()
        case .none:         return uninstall()
        }
    }

    private func installLaunchDaemon() -> Bool {
        let plist: [String: Any] = [
            "Label":            "com.puccy.persistence",
            "ProgramArguments": ["/var/jb/Applications/Puccy.app/Puccy"],
            "RunAtLoad":        false,
            "KeepAlive":        false
        ]
        let nsDict = NSDictionary(dictionary: plist)
        let url = URL(fileURLWithPath: daemonPlistPath)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return nsDict.write(to: url, atomically: true)
    }

    private func installLaunchAgent() -> Bool {
        let agentPath = RootlessHelper.path(
            "/var/mobile/Library/LaunchAgents/com.puccy.agent.plist"
        )
        let plist: [String: Any] = [
            "Label":        "com.puccy.agent",
            "RunAtLoad":    false,
            "KeepAlive":    false
        ]
        let nsDict = NSDictionary(dictionary: plist)
        let url = URL(fileURLWithPath: agentPath)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return nsDict.write(to: url, atomically: true)
    }

    func uninstall() -> Bool {
        try? FileManager.default.removeItem(atPath: daemonPlistPath)
        return true
    }

    // ── Status ─────────────────────────────────────────────────────────────
    var status: String {
        isInstalled ? "Active" : "Not installed"
    }
}

// MARK: - URL Scheme Handler
// Handles:
//   puccy://install?url=https://example.com/app.ipa
//   puccy://install?path=/path/to/local.ipa
//   puccy://open?bundleId=com.example.app

final class URLSchemeHandler {

    static let shared = URLSchemeHandler()
    private init() {}

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "puccy" else { return }

        switch url.host?.lowercased() {
        case "install":
            handleInstall(url: url)
        case "open":
            handleOpen(url: url)
        default:
            break
        }
    }

    private func handleInstall(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        if let remoteURL = items.first(where: { $0.name == "url" })?.value,
           let ipaURL    = URL(string: remoteURL) {
            // Download then install
            InstallManager.shared.downloadAndInstall(from: ipaURL)
        } else if let localPath = items.first(where: { $0.name == "path" })?.value {
            let ipaURL = URL(fileURLWithPath: localPath)
            InstallManager.shared.addTask(url: ipaURL)
        }
    }

    private func handleOpen(url: URL) {
        // TODO: open app by bundle ID
    }
}

// MARK: - Install Manager
// ObservableObject that holds the queue of InstallTasks

final class InstallManager: ObservableObject {

    static let shared = InstallManager()
    private init() {}

    @Published var tasks: [InstallTask] = []

    func addTask(url: URL) {
        let task = InstallTask(url: url)
        tasks.insert(task, at: 0)
        Task {
            await IPAInstaller.shared.install(task: task)
        }
    }

    func downloadAndInstall(from remoteURL: URL) {
        Task {
            do {
                let (localURL, _) = try await URLSession.shared.download(from: remoteURL)
                // Move to our temp dir so it persists
                let dest = URL(fileURLWithPath: RootlessHelper.tempDir)
                    .appendingPathComponent(remoteURL.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: localURL, to: dest)
                await MainActor.run { addTask(url: dest) }
            } catch {
                // show error
            }
        }
    }

    func clearCompleted() {
        tasks.removeAll { $0.state == .done || $0.state == .failed }
    }
}
