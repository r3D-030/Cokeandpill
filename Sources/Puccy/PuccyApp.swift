import SwiftUI

@main
struct PuccyApp: App {
    @StateObject private var installManager = InstallManager.shared
    @StateObject private var appManager    = AppManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(installManager)
                .environmentObject(appManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    URLSchemeHandler.shared.handle(url)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in
                    appManager.refresh()
                }
        }
    }
}
