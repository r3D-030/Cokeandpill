import Foundation
import Combine
import UIKit

// MARK: - App Manager
// Scans /var/jb/Applications and manages Puccy-installed apps

final class AppManager: ObservableObject {

    static let shared = AppManager()
    private init() { refresh() }

    @Published var apps:         [InstalledApp] = []
    @Published var isRefreshing: Bool           = false

    private let fm      = FileManager.default
    private let dataKey = "puccy.installed.apps"

    // ── Refresh ───────────────────────────────────────────────────────────
    func refresh() {
        isRefreshing = true
        Task.detached { [weak self] in
            guard let self else { return }
            let scanned = self.scanApplications()
            await MainActor.run {
                self.apps        = scanned
                self.isRefreshing = false
            }
        }
    }

    // ── Scan /var/jb/Applications ─────────────────────────────────────────
    private func scanApplications() -> [InstalledApp] {
        let appsPath = RootlessHelper.applicationsDir
        guard let contents = try? fm.contentsOfDirectory(atPath: appsPath) else {
            return []
        }

        return contents
            .filter { $0.hasSuffix(".app") }
            .compactMap { folder -> InstalledApp? in
                let fullPath = (appsPath as NSString).appendingPathComponent(folder)
                return buildApp(from: fullPath)
            }
            .sorted { $0.name < $1.name }
    }

    private func buildApp(from bundlePath: String) -> InstalledApp? {
        let infoPlist = (bundlePath as NSString).appendingPathComponent("Info.plist")
        guard
            let info = NSDictionary(contentsOfFile: infoPlist),
            let bid  = info["CFBundleIdentifier"] as? String,
            let name = info["CFBundleDisplayName"] as? String
                    ?? info["CFBundleName"] as? String
        else { return nil }

        let version = info["CFBundleShortVersionString"] as? String ?? "1.0"

        // Try to load icon
        let iconData = loadIcon(bundlePath: bundlePath, info: info)

        // Check if any tweaks injected
        let (injected, tweaks) = checkInjections(bundleId: bid)

        let attrs      = try? fm.attributesOfItem(atPath: bundlePath)
        let installDate = attrs?[.creationDate] as? Date ?? Date()

        return InstalledApp(
            id:              bid,
            name:            name,
            version:         version,
            bundlePath:      bundlePath,
            iconData:        iconData,
            installDate:     installDate,
            isInjected:      injected,
            injectedTweaks:  tweaks
        )
    }

    private func loadIcon(bundlePath: String, info: NSDictionary) -> Data? {
        let candidates = iconCandidates(from: info)
        for name in candidates {
            let p = (bundlePath as NSString).appendingPathComponent(name)
            if let data = try? Data(contentsOf: URL(fileURLWithPath: p)) {
                return data
            }
        }
        return nil
    }

    private func iconCandidates(from info: NSDictionary) -> [String] {
        var names: [String] = []
        if let icons = info["CFBundleIcons"] as? NSDictionary,
           let primary = icons["CFBundlePrimaryIcon"] as? NSDictionary,
           let files   = primary["CFBundleIconFiles"] as? [String] {
            names.append(contentsOf: files.reversed()) // prefer largest
        }
        names.append(contentsOf: ["AppIcon60x60@2x.png", "AppIcon@2x.png", "Icon.png"])
        return names
    }

    private func checkInjections(bundleId: String) -> (Bool, [String]) {
        let tweaks = ElleKitManager.shared.injections(for: bundleId)
        let enabled = tweaks.filter(\.isEnabled).map(\.tweakName)
        return (!enabled.isEmpty, enabled)
    }

    // ── Delete app ────────────────────────────────────────────────────────
    func deleteApp(_ app: InstalledApp, completion: @escaping (Result<Void, Error>) -> Void) {
        Task.detached {
            do {
                try FileManager.default.removeItem(atPath: app.bundlePath)
                RootlessHelper.uicacheAll()
                await MainActor.run {
                    self.apps.removeAll { $0.id == app.id }
                    completion(.success(()))
                }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }

    // ── Launch app via SpringBoard ─────────────────────────────────────────
    func launchApp(_ app: InstalledApp) {
        let urlStr = "puccy-launch://\(app.id)"
        if let url = URL(string: "apple-internal://\(app.id)") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
