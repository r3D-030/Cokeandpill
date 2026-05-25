import Foundation
import Combine

// MARK: - ElleKit Injection Manager
// Manages tweak injections via ElleKit's plist-based inject system
// Config lives at /var/jb/Library/ElleKit/inject.plist (rootless)

final class ElleKitManager: ObservableObject {

    static let shared = ElleKitManager()
    private init() { loadConfigs() }

    @Published var configs:      [InjectionConfig] = []
    @Published var isElleKitAvailable: Bool = false

    private let injectPlistPath = RootlessHelper.path("/Library/ElleKit/inject.plist")
    private let configPath: String = {
        RootlessHelper.puccyDataDir + "/injections.json"
    }()

    // ── Availability check ────────────────────────────────────────────────
    func checkAvailability() {
        let ellekitLib = RootlessHelper.path("/usr/lib/ElleKit.dylib")
        isElleKitAvailable = FileManager.default.fileExists(atPath: ellekitLib)
    }

    // ── Load saved configs ─────────────────────────────────────────────────
    func loadConfigs() {
        checkAvailability()
        guard
            let data    = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
            let decoded = try? JSONDecoder().decode([InjectionConfig].self, from: data)
        else { return }
        configs = decoded
    }

    // ── Save ──────────────────────────────────────────────────────────────
    func saveConfigs() {
        guard let data = try? JSONEncoder().encode(configs) else { return }
        try? data.write(to: URL(fileURLWithPath: configPath))
        writeElleKitPlist()
    }

    // ── Add injection ──────────────────────────────────────────────────────
    func addInjection(tweakName: String, dylibPath: String, targetApp: String) {
        let config = InjectionConfig(
            tweakName:  tweakName,
            dylibPath:  dylibPath,
            targetApp:  targetApp
        )
        configs.append(config)
        saveConfigs()
    }

    // ── Toggle injection ───────────────────────────────────────────────────
    func toggle(_ config: InjectionConfig) {
        guard let idx = configs.firstIndex(where: { $0.id == config.id }) else { return }
        configs[idx].isEnabled.toggle()
        saveConfigs()
    }

    // ── Remove ────────────────────────────────────────────────────────────
    func remove(_ config: InjectionConfig) {
        configs.removeAll { $0.id == config.id }
        saveConfigs()
    }

    // ── Get injections for a specific app ─────────────────────────────────
    func injections(for bundleId: String) -> [InjectionConfig] {
        configs.filter { $0.targetApp == bundleId }
    }

    // ── Write ElleKit plist ────────────────────────────────────────────────
    // ElleKit reads: /var/jb/Library/ElleKit/inject.plist
    // Format: { "bundleId": ["/path/to/tweak.dylib", ...] }
    private func writeElleKitPlist() {
        var plistDict: [String: [String]] = [:]

        for config in configs where config.isEnabled {
            if plistDict[config.targetApp] == nil {
                plistDict[config.targetApp] = []
            }
            plistDict[config.targetApp]?.append(config.dylibPath)
        }

        let plistURL = URL(fileURLWithPath: injectPlistPath)
        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        let nsDict = NSDictionary(dictionary: plistDict)
        nsDict.write(to: plistURL, atomically: true)
    }

    // ── Scan for available dylibs in TweakInject ───────────────────────────
    var availableDylibs: [String] {
        let tweaksDir = RootlessHelper.tweaksDir
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: tweaksDir) else {
            return []
        }
        return files
            .filter { $0.hasSuffix(".dylib") }
            .map { (tweaksDir as NSString).appendingPathComponent($0) }
    }
}
