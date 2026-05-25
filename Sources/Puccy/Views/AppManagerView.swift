import SwiftUI

struct AppManagerView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var search       = ""
    @State private var selectedApp: InstalledApp?
    @State private var showDetail   = false
    @State private var appToDelete: InstalledApp?
    @State private var showDeleteAlert = false

    var filteredApps: [InstalledApp] {
        guard !search.isEmpty else { return appManager.apps }
        return appManager.apps.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.id.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(PuccyTheme.textMuted)
                    TextField("Search apps…", text: $search)
                        .foregroundStyle(.white)
                        .font(PuccyTheme.bodyFont())
                }
                .padding(12)
                .background(PuccyTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        if appManager.isRefreshing {
                            ProgressView()
                                .tint(PuccyTheme.primary)
                                .padding(40)
                        } else if filteredApps.isEmpty {
                            EmptyStateView(
                                icon:    "square.stack.3d.up.slash",
                                title:   "No Apps",
                                message: search.isEmpty
                                    ? "Install an IPA from the Home tab."
                                    : "No apps match '\(search)'."
                            )
                        } else {
                            ForEach(filteredApps) { app in
                                Button {
                                    selectedApp = app
                                    showDetail  = true
                                } label: {
                                    AppRowView(app: app)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appToDelete    = app
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Uninstall", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(PuccyTheme.background)
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appManager.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(PuccyTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let app = selectedApp {
                AppDetailView(app: app)
            }
        }
        .alert("Uninstall \(appToDelete?.name ?? "")?", isPresented: $showDeleteAlert) {
            Button("Uninstall", role: .destructive) {
                if let app = appToDelete {
                    appManager.deleteApp(app) { _ in }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the app.")
        }
    }
}

// MARK: - App Detail
struct AppDetailView: View {
    let app: InstalledApp
    @Environment(\.dismiss) private var dismiss

    var injections: [InjectionConfig] {
        ElleKitManager.shared.injections(for: app.id)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // App info card
                    HStack(spacing: 14) {
                        app.icon
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(app.name)
                                .font(PuccyTheme.titleFont(20))
                                .foregroundStyle(.white)
                            Text(app.id)
                                .font(PuccyTheme.monoFont(11))
                                .foregroundStyle(PuccyTheme.textMuted)
                            StatusBadge(text: "v\(app.version)", color: PuccyTheme.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .puccyCard()

                    // Details
                    VStack(spacing: 0) {
                        DetailRow(label: "Bundle ID",   value: app.id)
                        Divider().background(PuccyTheme.cardBorder)
                        DetailRow(label: "Version",     value: app.version)
                        Divider().background(PuccyTheme.cardBorder)
                        DetailRow(label: "Install Path", value: app.bundlePath)
                        Divider().background(PuccyTheme.cardBorder)
                        DetailRow(
                            label: "Installed",
                            value: app.installDate.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                    .puccyCard()

                    // Injections
                    if !injections.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Active Injections")
                            ForEach(injections) { inj in
                                HStack {
                                    Image(systemName: "syringe.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(PuccyTheme.accent)
                                    Text(inj.tweakName)
                                        .font(PuccyTheme.bodyFont(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    StatusBadge(
                                        text: inj.isEnabled ? "ON" : "OFF",
                                        color: inj.isEnabled ? PuccyTheme.success : PuccyTheme.textMuted
                                    )
                                }
                                .padding(12)
                                .puccyCard()
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(PuccyTheme.background)
            .navigationTitle(app.name)
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

struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(PuccyTheme.bodyFont(14))
                .foregroundStyle(PuccyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(PuccyTheme.monoFont(12))
                .foregroundStyle(.white)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
