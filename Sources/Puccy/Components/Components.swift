import SwiftUI

// MARK: - Puccy Reusable Components

// ── Stat Card ──────────────────────────────────────────────────────────────
struct StatCard: View {
    let icon:    String
    let label:   String
    let value:   String
    var color:   Color = PuccyTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(PuccyTheme.titleFont(22))
                .foregroundStyle(.white)
            Text(label)
                .font(PuccyTheme.labelFont(11))
                .foregroundStyle(PuccyTheme.textSecondary)
        }
        .padding(16)
        .puccyCard()
    }
}

// ── Status Badge ────────────────────────────────────────────────────────────
struct StatusBadge: View {
    let text:  String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(PuccyTheme.labelFont(10))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }
}

// ── App Row ─────────────────────────────────────────────────────────────────
struct AppRowView: View {
    let app: InstalledApp
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            app.icon
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(PuccyTheme.bodyFont(15).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(app.id)
                    .font(PuccyTheme.monoFont(11))
                    .foregroundStyle(PuccyTheme.textMuted)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    StatusBadge(text: "v\(app.version)", color: PuccyTheme.textSecondary)
                    if app.isInjected {
                        StatusBadge(text: "Injected", color: PuccyTheme.accent)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PuccyTheme.textMuted)
        }
        .padding(14)
        .puccyCard()
    }
}

// ── Install Task Row ─────────────────────────────────────────────────────────
struct InstallTaskRow: View {
    @ObservedObject var task: InstallTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: task.state.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(task.state.color)
                Text(task.appName)
                    .font(PuccyTheme.bodyFont(14).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: task.state.rawValue, color: task.state.color)
            }

            if task.state != .done && task.state != .failed {
                ProgressView(value: task.progress)
                    .tint(PuccyTheme.primary)
                    .background(PuccyTheme.surface)
                    .clipShape(Capsule())
            }

            Text(task.error ?? task.message)
                .font(PuccyTheme.monoFont(11))
                .foregroundStyle(task.error != nil ? PuccyTheme.danger : PuccyTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .puccyCard()
    }
}

// ── Section Header ────────────────────────────────────────────────────────────
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(PuccyTheme.labelFont(11))
                .foregroundStyle(PuccyTheme.textMuted)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(PuccyTheme.labelFont(12))
                    .foregroundStyle(PuccyTheme.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

// ── Gradient Logo ──────────────────────────────────────────────────────────────
struct PuccyLogo: View {
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(PuccyTheme.gradient)
                .frame(width: size, height: size)
            Text("P")
                .font(.system(size: size * 0.55, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .shadow(color: PuccyTheme.primary.opacity(0.5), radius: size * 0.2)
    }
}

// ── Empty State ────────────────────────────────────────────────────────────────
struct EmptyStateView: View {
    let icon:    String
    let title:   String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PuccyTheme.primary.opacity(0.5))
            Text(title)
                .font(PuccyTheme.titleFont(20))
                .foregroundStyle(.white)
            Text(message)
                .font(PuccyTheme.bodyFont(14))
                .foregroundStyle(PuccyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
