import Foundation
import Combine

// MARK: - IPA Installer
// Pipeline: Copy → Extract → Sign (ldid2) → Install → uicache

final class IPAInstaller {

    static let shared = IPAInstaller()
    private init() {}

    private let fm = FileManager.default

    // ── Public install entry ──────────────────────────────────────────────
    func install(task: InstallTask) async {
        do {
            // 1. Extract
            let appBundleURL = try await extract(task: task)

            // 2. Sign
            try await sign(appBundleURL: appBundleURL, task: task)

            // 3. Install to Applications
            let installedURL = try await installBundle(appBundleURL, task: task)

            // 4. Register with SpringBoard
            await uicache(installedURL, task: task)

            await MainActor.run {
                task.state    = .done
                task.progress = 1.0
                task.message  = "✓ Installed successfully"
            }
        } catch {
            await MainActor.run {
                task.state   = .failed
                task.error   = error.localizedDescription
                task.message = "Failed: \(error.localizedDescription)"
            }
        }
    }

    // ── Step 1: Extract IPA ───────────────────────────────────────────────
    private func extract(task: InstallTask) async throws -> URL {
        await update(task, state: .extracting, progress: 0.1, msg: "Extracting IPA…")

        let tempDir = URL(fileURLWithPath: RootlessHelper.tempDir)
            .appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Use unzip (available in rootless as /var/jb/usr/bin/unzip)
        let unzip = RootlessHelper.path("/usr/bin/unzip")
        let result = RootlessHelper.run(
            unzip,
            args: ["-qo", task.ipaURL.path, "-d", tempDir.path]
        )
        guard result.exitCode == 0 else {
            throw PuccyError.extractionFailed(result.output)
        }

        await update(task, state: .extracting, progress: 0.3, msg: "Locating .app bundle…")

        // Find .app inside Payload/
        let payloadURL = tempDir.appendingPathComponent("Payload")
        let contents   = try fm.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: nil
        )
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw PuccyError.noBundleFound
        }

        return appBundle
    }

    // ── Step 2: Sign with ldid2 ───────────────────────────────────────────
    private func sign(appBundleURL: URL, task: InstallTask) async throws {
        await update(task, state: .signing, progress: 0.5, msg: "Signing with ldid2…")

        let executableName = try executableName(in: appBundleURL)
        let executablePath = appBundleURL.appendingPathComponent(executableName).path

        // Sign main executable
        let result = RootlessHelper.run(
            RootlessHelper.ldid2,
            args: ["-S", executablePath]
        )
        guard result.exitCode == 0 else {
            // Try fallback: sign all binaries
            try signAllBinaries(in: appBundleURL)
            return
        }

        // Sign all frameworks & dylibs inside bundle
        try signAllBinaries(in: appBundleURL)

        await update(task, state: .signing, progress: 0.65, msg: "Signature applied ✓")
    }

    private func signAllBinaries(in bundle: URL) throws {
        let enumerator = fm.enumerator(at: bundle, includingPropertiesForKeys: [.isRegularFileKey])
        while let fileURL = enumerator?.nextObject() as? URL {
            guard isMachO(fileURL) else { continue }
            RootlessHelper.run(RootlessHelper.ldid2, args: ["-S", fileURL.path])
        }
    }

    private func isMachO(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        let magic = handle.readData(ofLength: 4)
        handle.closeFile()
        guard magic.count == 4 else { return false }
        let bytes = [UInt8](magic)
        // Mach-O magic numbers
        let machOMagics: [[UInt8]] = [
            [0xCE, 0xFA, 0xED, 0xFE],  // MH_MAGIC
            [0xCF, 0xFA, 0xED, 0xFE],  // MH_MAGIC_64
            [0xBE, 0xBA, 0xFE, 0xCA],  // MH_CIGAM
            [0xBF, 0xBA, 0xFE, 0xCA],  // MH_CIGAM_64
            [0xCA, 0xFE, 0xBA, 0xBE],  // FAT_MAGIC
            [0xBF, 0xBA, 0xFE, 0xCA],
        ]
        return machOMagics.contains(bytes)
    }

    // ── Step 3: Copy bundle to Applications ──────────────────────────────
    private func installBundle(_ appBundleURL: URL, task: InstallTask) async throws -> URL {
        await update(task, state: .installing, progress: 0.75, msg: "Installing to Applications…")

        let appsDir = URL(fileURLWithPath: RootlessHelper.applicationsDir)
        let dest    = appsDir.appendingPathComponent(appBundleURL.lastPathComponent)

        // Remove existing if present
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }

        try fm.copyItem(at: appBundleURL, to: dest)

        // Set correct permissions
        let attrs: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
        try fm.setAttributes(attrs, ofItemAtPath: dest.path)
        RootlessHelper.run("/bin/chmod", args: ["-R", "755", dest.path])

        await update(task, state: .installing, progress: 0.9, msg: "Bundle installed ✓")
        return dest
    }

    // ── Step 4: uicache ───────────────────────────────────────────────────
    private func uicache(_ installedURL: URL, task: InstallTask) async {
        await update(task, state: .installing, progress: 0.95, msg: "Registering with SpringBoard…")
        RootlessHelper.uicacheApp(at: installedURL.path)
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    private func executableName(in bundle: URL) throws -> String {
        let infoPlistURL = bundle.appendingPathComponent("Info.plist")
        guard
            let plist = NSDictionary(contentsOf: infoPlistURL),
            let name  = plist["CFBundleExecutable"] as? String
        else { throw PuccyError.invalidBundle }
        return name
    }

    @MainActor
    private func update(_ task: InstallTask, state: InstallTask.TaskState, progress: Double, msg: String) {
        task.state    = state
        task.progress = progress
        task.message  = msg
    }
}

// MARK: - Errors
enum PuccyError: LocalizedError {
    case extractionFailed(String)
    case noBundleFound
    case invalidBundle
    case signingFailed(String)
    case installFailed(String)
    case rootlessNotAvailable

    var errorDescription: String? {
        switch self {
        case .extractionFailed(let d): return "IPA extraction failed: \(d)"
        case .noBundleFound:           return "No .app bundle found in IPA"
        case .invalidBundle:           return "Invalid app bundle (missing Info.plist)"
        case .signingFailed(let d):    return "ldid2 signing failed: \(d)"
        case .installFailed(let d):    return "Installation failed: \(d)"
        case .rootlessNotAvailable:    return "Rootless jailbreak not detected"
        }
    }
}
