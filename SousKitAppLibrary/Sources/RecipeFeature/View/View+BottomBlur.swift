import DesignSystem
import SwiftUI

private struct BottomBlurModifier: ViewModifier {
    let radius: Double
    let height: Double
    let fullHeight: Double

    func body(content: Content) -> some View {
        // The blur samples this far past a pixel, so the layer is given room for it and cut back after.
        let reach = radius * 2.5
        let blurRadius = radius
        let blurHeight = height
        let fullBlurHeight = fullHeight

        content
            .visualEffect { content, proxy in
                let size = proxy.size
                let start = max(0.0, size.height - blurHeight)
                let end = size.height - fullBlurHeight

                return content
                    .layerEffect(
                        Self.pass(
                            size: size,
                            start: start,
                            end: end,
                            radius: blurRadius,
                            direction: CGPoint(x: 1.0, y: 0.0)
                        ),
                        maxSampleOffset: CGSize(width: reach, height: 0.0)
                    )
                    .layerEffect(
                        Self.pass(
                            size: size,
                            start: start,
                            end: end,
                            radius: blurRadius,
                            direction: CGPoint(x: 0.0, y: 1.0)
                        ),
                        maxSampleOffset: CGSize(width: 0.0, height: reach)
                    )
            }
            .clipped()
    }

    // A Gaussian blur is two passes of one direction each, across and then down.
    nonisolated private static func pass(
        size: CGSize,
        start: Double,
        end: Double,
        radius: Double,
        direction: CGPoint
    ) -> Shader {
        ShaderLibrary.bundle(.module).bottomBlur(
            .float2(size),
            .float(start),
            .float(end),
            .float(radius),
            .float2(direction)
        )
    }
}

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
        modifier(
            BottomBlurModifier(
                radius: radius,
                height: height,
                fullHeight: fullHeight
            )
        )
    }
}

#Preview("Bottom blur") {
    SousPlaceholder(symbol: "birthday.cake", color: .orange, symbolFont: .largeTitle)
        .frame(height: 160.0)
        .bottomBlur(radius: 8.0, height: 160.0, fullHeight: 40.0)
        .sousPagePadding()
        .sousPage()
}
