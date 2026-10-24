import DesignSystem
import SwiftUI

extension View {
    /// Blurs the bottom of this view, more strongly towards its bottom edge.
    ///
    /// - Parameters:
    ///   - radius: The blur's radius where it is strongest.
    ///   - height: How far up from the bottom edge the blur reaches.
    ///   - fullHeight: How far up from the bottom edge the blur is at its strongest.
    /// - Returns: The view, blurred.
    func bottomBlur(
        radius: Double,
        height: Double,
        fullHeight: Double
    ) -> some View {
        // The shader samples this far past a pixel, so the layer is given room for it and cut back after.
        let reach = radius * 2.5

        return visualEffect { content, proxy in
            let size = proxy.size

            // A Gaussian blur is two passes of one direction each, across and then down.
            func pass(_ direction: CGPoint) -> Shader {
                ShaderLibrary.bundle(.module).bottomBlur(
                    .float2(size),
                    .float(max(0.0, size.height - height)),
                    .float(size.height - fullHeight),
                    .float(radius),
                    .float2(direction)
                )
            }

            return content
                .layerEffect(pass(CGPoint(x: 1.0, y: 0.0)), maxSampleOffset: CGSize(width: reach, height: 0.0))
                .layerEffect(pass(CGPoint(x: 0.0, y: 1.0)), maxSampleOffset: CGSize(width: 0.0, height: reach))
        }
        .clipped()
    }
}

#Preview("Bottom blur") {
    SousPlaceholder(
        symbol: "birthday.cake",
        color: .orange,
        symbolFont: .largeTitle
    )
    .frame(height: 160.0)
    .bottomBlur(
        radius: 8.0,
        height: 160.0,
        fullHeight: 40.0
    )
    .sousPagePadding()
    .sousPage()
}
