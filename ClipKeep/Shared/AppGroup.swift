import Foundation

/// Shared container used by the app and the keyboard extension.
/// Must match the App Group in both .entitlements files (see project.yml).
enum AppGroup {
    static let identifier = "group.com.abdulwazery.clipkeep"

    /// `nil` when the App Group is not configured or the keyboard has no "Full Access".
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var isAvailable: Bool { sharedContainerURL != nil }

    /// Falls back to the private Documents folder so the app still works without the App Group.
    static var containerURL: URL {
        sharedContainerURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
