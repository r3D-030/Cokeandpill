import Foundation

// MARK: - Rootless Environment Helper
// Handles path differences between rootless jailbreaks:
//   Dopamine  → /var/jb  (symlink farm)
//   palera1n  → /var/jb  (same prefix via overlay)

enum RootlessHelper {

    // ── Prefix detection ─────────────────────────────────────────────────
    static let jbPrefix: String = {
        // Dopamine & palera1n both use /var/jb
        if FileManager.default.fileExists(atPath: "/var/jb") {
            return "/var/jb"
        }
        // Fallback: check common rootful indicators
        if FileManager.default.fileExists(atPath: "/usr/bin/ldid") {
            return ""
        }
        return "/var/jb"  // default to rootless
    }()

    static var isRootless: Bool { !jbPrefix.isEmpty }

    // ── Rootless path builder ─────────────────────────────────────────────
    static func path(_ suffix: String) -> String {
        "\(jbPrefix)\(suffix)"
    }

    // ── Key binary paths ──────────────────────────────────────────────────
    static var ldid:    String { path("/usr/bin/ldid2") }
    static var ldid2:   String { path("/usr/bin/ldid2") }
    static var uicache: String { path("/usr/bin/uicache") }
    static var bash:    String { path("/bin/bash") }
    static var dpkg:    String { path("/usr/bin/dpkg") }

    // ── Directories ───────────────────────────────────────────────────────
    static var applicationsDir: String { path("/Applications") }
    static var tweaksDir:       String { path("/usr/lib/TweakInject") }
    static var puccyDataDir:    String {
        let base = "/var/mobile/Library/Puccy"
        try? FileManager.default.createDirectory(
            atPath: base, withIntermediateDirectories: true
        )
        return base
    }
    static var tempDir: String {
        let tmp = puccyDataDir + "/tmp"
        try? FileManager.default.createDirectory(
            atPath: tmp, withIntermediateDirectories: true
        )
        return tmp
    }

    // ── Run a process ─────────────────────────────────────────────────────
    @discardableResult
    static func run(
        _ executable: String,
        args: [String],
        environment: [String: String]? = nil
    ) -> (output: String, exitCode: Int32) {
        let task   = Process()
        let pipe   = Pipe()
        let errPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments     = args
        task.standardOutput = pipe
        task.standardError  = errPipe

        if let env = environment {
            var base = ProcessInfo.processInfo.environment
            env.forEach { base[$0] = $1 }
            task.environment = base
        }

        do {
            try task.launch()
            task.waitUntilExit()
        } catch {
            return ("Launch error: \(error.localizedDescription)", -1)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out  = String(data: data, encoding: .utf8) ?? ""
        return (out.trimmingCharacters(in: .whitespacesAndNewlines), task.terminationStatus)
    }

    // ── Detect active jailbreak ────────────────────────────────────────────
    static var jailbreakName: String {
        if FileManager.default.fileExists(atPath: "/var/jb/.installed_dopamine") {
            return "Dopamine"
        }
        if FileManager.default.fileExists(atPath: "/var/jb/.installed_palera1n") {
            return "palera1n"
        }
        if FileManager.default.fileExists(atPath: "/var/jb") {
            return "Rootless (Unknown)"
        }
        return "Unknown"
    }

    static var jailbreakVersion: String {
        let versionFiles = [
            "/var/jb/.installed_dopamine",
            "/var/jb/.installed_palera1n"
        ]
        for file in versionFiles {
            if let v = try? String(contentsOfFile: file, encoding: .utf8) {
                return v.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return "Unknown"
    }

    // ── uicache ────────────────────────────────────────────────────────────
    static func uicacheApp(at path: String) -> Bool {
        let result = run(uicache, args: ["--path", path])
        return result.exitCode == 0
    }

    static func uicacheAll() -> Bool {
        let result = run(uicache, args: ["-a"])
        return result.exitCode == 0
    }
}
