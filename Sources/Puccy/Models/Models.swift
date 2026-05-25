import Foundation
import SwiftUI

// MARK: - Installed App
struct InstalledApp: Identifiable, Codable, Equatable {
    let id:          String   // bundle identifier
    var name:        String
    var version:     String
    var bundlePath:  String
    var iconData:    Data?
    var installDate: Date
    var isInjected:  Bool     // ElleKit injection active
    var injectedTweaks: [String]

    var icon: Image {
        if let data = iconData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "app.fill")
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Install Task
class InstallTask: ObservableObject, Identifiable {
    let id = UUID()
    let ipaURL: URL

    @Published var state:    TaskState = .pending
    @Published var progress: Double    = 0
    @Published var message:  String    = "Waiting..."
    @Published var error:    String?

    var appName: String { ipaURL.deletingPathExtension().lastPathComponent }

    enum TaskState: String {
        case pending    = "Pending"
        case extracting = "Extracting"
        case signing    = "Signing"
        case installing = "Installing"
        case done       = "Done"
        case failed     = "Failed"

        var color: Color {
            switch self {
            case .pending:    return PuccyTheme.textMuted
            case .extracting: return PuccyTheme.info
            case .signing:    return PuccyTheme.warning
            case .installing: return PuccyTheme.secondary
            case .done:       return PuccyTheme.success
            case .failed:     return PuccyTheme.danger
            }
        }

        var icon: String {
            switch self {
            case .pending:    return "clock"
            case .extracting: return "archivebox"
            case .signing:    return "signature"
            case .installing: return "arrow.down.circle"
            case .done:       return "checkmark.circle.fill"
            case .failed:     return "xmark.circle.fill"
            }
        }
    }

    init(url: URL) { self.ipaURL = url }
}

// MARK: - Injection Config
struct InjectionConfig: Codable, Identifiable {
    let id: UUID
    var tweakName:  String
    var dylibPath:  String
    var targetApp:  String    // bundle id
    var isEnabled:  Bool

    init(tweakName: String, dylibPath: String, targetApp: String) {
        self.id         = UUID()
        self.tweakName  = tweakName
        self.dylibPath  = dylibPath
        self.targetApp  = targetApp
        self.isEnabled  = true
    }
}
