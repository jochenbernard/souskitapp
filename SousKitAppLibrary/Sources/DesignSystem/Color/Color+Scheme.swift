import SwiftUI

extension Color {
    /// Creates a color that reads the scheme it is drawn in and takes the value for it.
    ///
    /// - Parameters:
    ///   - light: The value on a light scheme.
    ///   - dark: The value on a dark scheme.
    init(light: Color, dark: Color) {
        self.init(
            uiColor: UIColor { traits in
                UIColor(traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}
