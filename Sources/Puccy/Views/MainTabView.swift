import SwiftUI

struct MainTabView: View {
    @State private var selected: Tab = .home

    enum Tab: String, CaseIterable {
        case home        = "house.fill"
        case apps        = "square.grid.2x2.fill"
        case inject      = "syringe.fill"
        case persistence = "bolt.shield.fill"
        case settings    = "gearshape.fill"

        var label: String {
            switch self {
            case .home:        return "Home"
            case .apps:        return "Apps"
            case .inject:      return "Inject"
            case .persistence: return "Persist"
            case .settings:    return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selected {
                case .home:        HomeView()
                case .apps:        AppManagerView()
                case .inject:      InjectView()
                case .persistence: PersistenceView()
                case .settings:    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom tab bar
            CustomTabBar(selected: $selected)
        }
        .background(PuccyTheme.background.ignoresSafeArea())
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selected: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected == tab {
                                Capsule()
                                    .fill(PuccyTheme.primary.opacity(0.18))
                                    .frame(width: 44, height: 28)
                            }
                            Image(systemName: tab.rawValue)
                                .font(.system(size: 16, weight: selected == tab ? .semibold : .regular))
                                .foregroundStyle(selected == tab ? PuccyTheme.primary : PuccyTheme.textMuted)
                        }
                        Text(tab.label)
                            .font(PuccyTheme.labelFont(10))
                            .foregroundStyle(selected == tab ? PuccyTheme.primary : PuccyTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            ZStack {
                PuccyTheme.card
                Rectangle()
                    .fill(PuccyTheme.primary.opacity(0.06))
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    topTrailingRadius: 22
                )
            )
            .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    topTrailingRadius: 22
                )
                .stroke(PuccyTheme.cardBorder, lineWidth: 1)
            )
        )
    }
}
