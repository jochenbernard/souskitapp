import SwiftUI

/// The button that opens the settings, for the toolbar of the screen they open over.
public struct SettingsButton: View {
    private let action: @MainActor () -> Void

    /// Creates a button.
    ///
    /// - Parameter action: What opens the settings.
    public init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(
                title: { Text("Settings", bundle: .module) },
                icon: { Image(systemName: "gearshape") }
            )
        }
    }
}

#Preview("Settings button") {
    NavigationStack {
        Color.clear
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton(action: {})
                }
            }
    }
}
