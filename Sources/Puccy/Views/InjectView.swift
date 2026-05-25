import SwiftUI

struct InjectView: View {
    @EnvironmentObject var appManager: AppManager
    @ObservedObject private var elleKit = ElleKitManager.shared

    @State private var showAddSheet   = false
    @State private var selectedApp    = ""
    @State private var selectedDylib  = ""
    @State private var tweakName      = ""

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // ElleKit status card
                    statusCard

                    // Active injections
                    if elleKit.configs.isEmpty {
                        EmptyStateView(
                            icon:    "syringe",
                            title:   "No Injections",
                            message: "Tap + to inject an ElleKit tweak into any installed app."
                        )
                        .padding(.top, 40)
                    } else {
                        SectionHeader(title: "Active Injections")
                        ForEach(elleKit.configs) { config in
                            InjectionRow(config: config)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(PuccyTheme.background)
            .navigationTitle("Inject")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(PuccyTheme.primary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddInjectionSheet(apps: appManager.apps)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        elleKit.isElleKitAvailable
                        ? PuccyTheme.success.opacity(0.15)
                        : PuccyTheme.danger.opacity(0.15)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: elleKit.isElleKitAvailable ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        elleKit.isElleKitAvailable ? PuccyTheme.success : PuccyTheme.danger
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ElleKit")
                    .font(PuccyTheme.bodyFont(15).weight(.semibold))
                    .foregroundStyle(.white)
                Text(
                    elleKit.isElleKitAvailable
                    ? "Available — \(elleKit.configs.count) injection(s) configured"
                    : "Not found at \(RootlessHelper.path("/usr/lib/ElleKit.dylib"))"
                )
                .font(PuccyTheme.bodyFont(12))
                .foregroundStyle(PuccyTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .puccyCard()
    }
}

// MARK: - Injection Row
struct InjectionRow: View {
    let config: InjectionConfig
    @ObservedObject private var elleKit = ElleKitManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "syringe.fill")
                .font(.system(size: 16))
                .foregroundStyle(config.isEnabled ? PuccyTheme.accent : PuccyTheme.textMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(config.tweakName)
                    .font(PuccyTheme.bodyFont(14).weight(.semibold))
                    .foregroundStyle(.white)
                Text("→ \(config.targetApp)")
                    .font(PuccyTheme.monoFont(11))
                    .foregroundStyle(PuccyTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { _ in elleKit.toggle(config) }
            ))
            .tint(PuccyTheme.primary)
            .scaleEffect(0.85)
        }
        .padding(14)
        .puccyCard()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                elleKit.remove(config)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Injection Sheet
struct AddInjectionSheet: View {
    let apps: [InstalledApp]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var elleKit = ElleKitManager.shared

    @State private var tweakName    = ""
    @State private var selectedApp  = ""
    @State private var selectedDylib = ""
    @State private var customDylib  = ""
    @State private var useCustom    = false

    var availableDylibs: [String] { elleKit.availableDylibs }
    var finalDylibPath: String { useCustom ? customDylib : selectedDylib }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Tweak name
                    FormField(label: "Tweak Name") {
                        TextField("My Tweak", text: $tweakName)
                            .foregroundStyle(.white)
                    }

                    // Target app picker
                    FormField(label: "Target App") {
                        Picker("", selection: $selectedApp) {
                            Text("Select…").tag("")
                            ForEach(apps) { app in
                                Text(app.name).tag(app.id)
                            }
                        }
                        .foregroundStyle(.white)
                    }

                    // Dylib
                    Toggle("Custom dylib path", isOn: $useCustom)
                        .tint(PuccyTheme.primary)
                        .padding(16)
                        .puccyCard()

                    if useCustom {
                        FormField(label: "Dylib Path") {
                            TextField("/var/jb/usr/lib/...", text: $customDylib)
                                .foregroundStyle(.white)
                                .font(PuccyTheme.monoFont(13))
                        }
                    } else {
                        FormField(label: "Select Dylib") {
                            Picker("", selection: $selectedDylib) {
                                Text("Select…").tag("")
                                ForEach(availableDylibs, id: \.self) { path in
                                    Text(URL(fileURLWithPath: path).lastPathComponent)
                                        .tag(path)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                    }

                    Button("Add Injection") {
                        guard !tweakName.isEmpty, !selectedApp.isEmpty, !finalDylibPath.isEmpty else { return }
                        elleKit.addInjection(
                            tweakName:  tweakName,
                            dylibPath:  finalDylibPath,
                            targetApp:  selectedApp
                        )
                        dismiss()
                    }
                    .puccyButton()
                    .disabled(tweakName.isEmpty || selectedApp.isEmpty || finalDylibPath.isEmpty)
                    .opacity(tweakName.isEmpty || selectedApp.isEmpty || finalDylibPath.isEmpty ? 0.5 : 1)
                }
                .padding(16)
            }
            .background(PuccyTheme.background.ignoresSafeArea())
            .navigationTitle("Add Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PuccyTheme.primary)
                }
            }
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(PuccyTheme.labelFont(11))
                .foregroundStyle(PuccyTheme.textMuted)
            content
                .padding(14)
                .background(PuccyTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
