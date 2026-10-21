import SwiftUI

extension Color {
    /// Creates an sRGB color from OKLCH coordinates, with the hue in degrees.
    init(
        oklchLightness lightness: Double,
        chroma: Double,
        hue: Double
    ) {
        let radians = hue * .pi / 180.0
        let greenRed = chroma * cos(radians)
        let blueYellow = chroma * sin(radians)

        // OKLab to cone responses to linear sRGB, with the matrices OKLab was published with.
        let long = pow(lightness + 0.3963377774 * greenRed + 0.2158037573 * blueYellow, 3.0)
        let medium = pow(lightness - 0.1055613458 * greenRed - 0.0638541728 * blueYellow, 3.0)
        let short = pow(lightness - 0.0894841775 * greenRed - 1.2914855480 * blueYellow, 3.0)

        self.init(
            .sRGBLinear,
            red: 4.0767416621 * long - 3.3077115913 * medium + 0.2309699292 * short,
            green: -1.2684380046 * long + 2.6097574011 * medium - 0.3413193965 * short,
            blue: -0.0041960863 * long - 0.7034186147 * medium + 1.7076147010 * short,
            opacity: 1.0
        )
    }
}
