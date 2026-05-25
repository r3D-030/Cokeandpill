import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var installManager: InstallManager
    @EnvironmentObject var appManager:     AppManager

    @State private var showFilePicker   = false
    @State private var showURLSheet     = false
    @State private var urlInput         = ""
    @State private var headerScale      = 0.8
    @State private var headerOpacity    = 0.0

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // ── Hero ──────────────────────────────────────────────
                    heroSection
                        .scaleEffect(headerScale)
                        .opacity(headerOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                headerScale   = 1.0
                                headerOpacity = 1.0
                            }
                        }

                    // ── Stats ─────────────────────────────────────────────
                    statsRow

                    // ── Install actions ───────────────────────────────────
                    SectionHeader(title: "Install IPA")
                    installActions

                    // ── Queue ─────────────────────────────────────────────
                    if !installManager.tasks.isEmpty {
                        SectionHeader(
                            title: "Queue",
                            action: "Clear",
                            onAction: { installManager.clearCompleted() }
                        )
                        ForEach(installManager.tasks) { task in
                            InstallTaskRow(task: task)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(PuccyTheme.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showFilePicker) { ipaFilePicker }
        .sheet(isPresented: $showURLSheet)   { urlInstallSheet }
    }

    // ── Hero section ───────────────────────────────────────────────────────
    private var heroSection: some View {
        VStack(spacing: 4) {
            HStack {
                PuccyLogo(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Puccy")
                        .font(PuccyTheme.titleFont(26))
                        .foregroundStyle(.white)
                    Text("Rootless IPA Installer")
                        .font(PuccyTheme.labelFont(12))
                        .foregroundStyle(PuccyTheme.textSecondary)
                }
                Spacer()
                // JB badge
                VStack(alignment: .trailing, spacing: 2) {
                    StatusBadge(
                        text: RootlessHelper.jailbreakName,
                        color: PuccyTheme.success
                    )
                    Text("Rootless")
                        .font(PuccyTheme.labelFont(10))
                        .foregroundStyle(PuccyTheme.textMuted)
                }
            }
        }
        .padding(.top, 8)
    }

    // ── Stats ──────────────────────────────────────────────────────────────
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                icon:  "square.stack.3d.up.fill",
                label: "Installed",
                value: "\(appManager.apps.count)",
                color: PuccyTheme.primary
            )
            StatCard(
                icon:  "syringe.fill",
                label: "Injections",
                value: "\(ElleKitManager.shared.configs.filter(\.isEnabled).count)",
                color: PuccyTheme.accent
            )
            StatCard(
                icon:  "bolt.shield.fill",
                label: "Persistence",
                value: PersistenceHelper.shared.isInstalled ? "ON" : "OFF",
                color: PersistenceHelper.shared.isInstalled ? PuccyTheme.success : PuccyTheme.textMuted
            )
        }
    }

    // ── Install action buttons ─────────────────────────────────────────────
    private var installActions: some View {
        VStack(spacing: 10) {
            // Primary: file picker
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Install IPA from Files")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .opacity(0.5)
                }
                .padding(16)
                .background(PuccyTheme.gradient)
                .foregroundStyle(.white)
                .font(PuccyTheme.bodyFont(15).weight(.semibold))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Secondary: URL scheme
            Button {
                showURLSheet = true
            } label: {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Install from URL")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .opacity(0.5)
                }
                .padding(16)
                .background(PuccyTheme.card)
                .foregroundStyle(PuccyTheme.secondary)
                .font(PuccyTheme.bodyFont(15).weight(.medium))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PuccyTheme.primary.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // ── File picker ────────────────────────────────────────────────────────
    private var ipaFilePicker: some View {
        DocumentPickerView(
            contentTypes: [.init(filenameExtension: "ipa") ?? .zip]
        ) { url in
            installManager.addTask(url: url)
            showFilePicker = false
        }
    }

    // ── URL install sheet ──────────────────────────────────────────────────
    private var urlInstallSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("IPA URL")
                        .font(PuccyTheme.labelFont(12))
                        .foregroundStyle(PuccyTheme.textSecondary)
                    TextField("https://example.com/app.ipa", text: $urlInput)
                        .font(PuccyTheme.monoFont(14))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(PuccyTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Button("Download & Install") {
                    guard let url = URL(string: urlInput) else { return }
                    installManager.downloadAndInstall(from: url)
                    showURLSheet = false
                }
                .puccyButton()
                .disabled(urlInput.isEmpty)

                Spacer()
            }
            .padding(20)
            .background(PuccyTheme.background.ignoresSafeArea())
            .navigationTitle("Install from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showURLSheet = false }
                        .foregroundStyle(PuccyTheme.primary)
                }
            }
        }
    }
}

// MARK: - Document Picker Wrapper
struct DocumentPickerView: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        vc.delegate = context.coordinator
        vc.allowsMultipleSelection = false
        return vc
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            // Copy to our temp dir
            let dest = URL(fileURLWithPath: RootlessHelper.tempDir)
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: dest)
            url.stopAccessingSecurityScopedResource()
            onPick(dest)
        }
    }
}
