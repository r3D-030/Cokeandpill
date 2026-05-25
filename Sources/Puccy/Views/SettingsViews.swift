import SwiftUI

// MARK: - Persistence View
struct PersistenceView: View {
    @State private var method: PersistenceHelper.PersistenceMethod = .launchDaemon
    @State private var isInstalled = PersistenceHelper.shared.isInstalled
    @State private var isLoading   = false
    @State private var resultMsg   = ""
    @State private var showResult  = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Status card
                    VStack(spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(isInstalled ? PuccyTheme.success.opacity(0.15) : PuccyTheme.danger.opacity(0.1))
                                    .frame(width: 52, height: 52)
                                Image(systemName: isInstalled ? "bolt.shield.fill" : "bolt.shield")
                                    .font(.system(size: 24))
                                    .foregroundStyle(isInstalled ? PuccyTheme.success : PuccyTheme.textMuted)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Persistence")
                                    .font(PuccyTheme.titleFont(18))
                                    .foregroundStyle(.white)
                                StatusBadge(
                                    text: isInstalled ? "Active" : "Inactive",
                                    color: isInstalled ? PuccyTheme.success : PuccyTheme.textMuted
                                )
                            }
                            Spacer()
                        }

                        Text("Persistence ensures Puccy survives reboots and re-jailbreaks by registering a LaunchDaemon or LaunchAgent with the rootless jailbreak.")
                            .font(PuccyTheme.bodyFont(13))
                            .foregroundStyle(PuccyTheme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .puccyCard()

                    // Method picker
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Method")
                        ForEach(PersistenceHelper.PersistenceMethod.allCases, id: \.self) { m in
                            Button {
                                method = m
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(m.rawValue)
                                            .font(PuccyTheme.bodyFont(15).weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(m.description)
                                            .font(PuccyTheme.bodyFont(12))
                                            .foregroundStyle(PuccyTheme.textSecondary)
                                    }
                                    Spacer()
                                    if method == m {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(PuccyTheme.primary)
                                    }
                                }
                                .padding(14)
                                .puccyCard(elevated: method == m)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Action button
                    Button {
                        togglePersistence()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: isInstalled ? "xmark.shield" : "bolt.shield.fill")
                                Text(isInstalled ? "Remove Persistence" : "Install Persistence")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .puccyButton(isInstalled ? .secondary : .primary)
                    .disabled(isLoading)

                    if showResult {
                        Text(resultMsg)
                            .font(PuccyTheme.bodyFont(13))
                            .foregroundStyle(PuccyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(PuccyTheme.background)
            .navigationTitle("Persistence")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func togglePersistence() {
        isLoading = true
        DispatchQueue.global().async {
            let success: Bool
            if isInstalled {
                success = PersistenceHelper.shared.uninstall()
            } else {
                success = PersistenceHelper.shared.install(method: method)
            }
            DispatchQueue.main.async {
                isLoading   = false
                isInstalled = PersistenceHelper.shared.isInstalled
                resultMsg   = success ? "Done ✓" : "Failed — check permissions"
                showResult  = true
            }
        }
    }
}

extension PersistenceHelper.PersistenceMethod {
    var description: String {
        switch self {
        case .launchDaemon: return "Registers as a system daemon. Most reliable."
        case .launchAgent:  return "Registers as a user agent. Safer, limited."
        case .none:         return "Remove persistence entirely."
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var showLogs      = false
    @State private var showAbout     = false
    @State private var clearCacheAlert = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Jailbreak info
                    jbInfoCard

                    // Options
                    VStack(spacing: 0) {
                        SettingsRow(icon: "terminal.fill", label: "View Logs", color: PuccyTheme.info) {
                            showLogs = true
                        }
                        Divider().background(PuccyTheme.cardBorder).padding(.leading, 52)
                        SettingsRow(icon: "trash.fill", label: "Clear Cache", color: PuccyTheme.warning) {
                            clearCacheAlert = true
                        }
                        Divider().background(PuccyTheme.cardBorder).padding(.leading, 52)
                        SettingsRow(icon: "arrow.clockwise", label: "Rebuild uicache", color: PuccyTheme.success) {
                            RootlessHelper.uicacheAll()
                        }
                        Divider().background(PuccyTheme.cardBorder).padding(.leading, 52)
                        SettingsRow(icon: "info.circle.fill", label: "About Puccy", color: PuccyTheme.primary) {
                            showAbout = true
                        }
                    }
                    .puccyCard()

                    // URL scheme info
                    urlSchemeCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(PuccyTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showLogs)  { LogsView() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .alert("Clear cache?", isPresented: $clearCacheAlert) {
            Button("Clear", role: .destructive) {
                try? FileManager.default.removeItem(atPath: RootlessHelper.tempDir)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var jbInfoCard: some View {
        VStack(spacing: 10) {
            HStack {
                PuccyLogo(size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Puccy v1.0.0")
                        .font(PuccyTheme.bodyFont(15).weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Rootless IPA Installer")
                        .font(PuccyTheme.bodyFont(12))
                        .foregroundStyle(PuccyTheme.textSecondary)
                }
                Spacer()
            }
            Divider().background(PuccyTheme.cardBorder)
            HStack {
                infoItem(label: "Jailbreak", value: RootlessHelper.jailbreakName)
                Spacer()
                infoItem(label: "iOS", value: UIDevice.current.systemVersion)
                Spacer()
                infoItem(label: "Prefix", value: RootlessHelper.jbPrefix.isEmpty ? "/" : RootlessHelper.jbPrefix)
            }
        }
        .padding(16)
        .puccyCard()
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PuccyTheme.bodyFont(14).weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(PuccyTheme.labelFont(10))
                .foregroundStyle(PuccyTheme.textMuted)
        }
    }

    private var urlSchemeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "URL Scheme")
            VStack(alignment: .leading, spacing: 6) {
                schemeExample("puccy://install?url=https://…/app.ipa")
                schemeExample("puccy://install?path=/var/mobile/…/app.ipa")
            }
        }
        .padding(16)
        .puccyCard()
    }

    private func schemeExample(_ str: String) -> some View {
        Text(str)
            .font(PuccyTheme.monoFont(11))
            .foregroundStyle(PuccyTheme.secondary)
            .padding(8)
            .background(PuccyTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SettingsRow: View {
    let icon:    String
    let label:   String
    let color:   Color
    let action:  () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(PuccyTheme.bodyFont())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(PuccyTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Logs View
struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    let logs = PuccyLogger.shared.entries

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs.reversed(), id: \.self) { entry in
                        Text(entry)
                            .font(PuccyTheme.monoFont(11))
                            .foregroundStyle(PuccyTheme.textSecondary)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(PuccyTheme.background)
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PuccyTheme.primary)
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                PuccyLogo(size: 80)
                VStack(spacing: 6) {
                    Text("Puccy")
                        .font(PuccyTheme.titleFont(32))
                        .foregroundStyle(.white)
                    Text("Version 1.0.0")
                        .font(PuccyTheme.labelFont(14))
                        .foregroundStyle(PuccyTheme.textSecondary)
                }
                Text("A rootless IPA installer and app manager for Dopamine and palera1n rootless jailbreaks. Supports permanent installs, ElleKit injections, and URL scheme installations.")
                    .font(PuccyTheme.bodyFont(15))
                    .foregroundStyle(PuccyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .padding(.top, 40)
            .background(PuccyTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PuccyTheme.primary)
                }
            }
        }
    }
}

// MARK: - Logger
final class PuccyLogger {
    static let shared = PuccyLogger()
    private init() {}
    private(set) var entries: [String] = []

    func log(_ msg: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        entries.append("[\(ts)] \(msg)")
        if entries.count > 200 { entries.removeFirst() }
    }
}
