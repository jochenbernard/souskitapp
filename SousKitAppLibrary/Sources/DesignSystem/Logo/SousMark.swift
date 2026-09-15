import SwiftUI

/// The Sous mark: curls of steam over a plate, drawn on a 64-unit grid.
///
/// `size` is the edge of that grid, and the grid carries the mark's clearspace. The mark
/// takes no extra padding.
public struct SousMark: View {
    /// Which cut of the mark to draw.
    public enum Cut: Sendable, Hashable {
        /// ``threeCurl`` down to the 24pt floor on light, and above it on dark.
        case automatic

        /// The full mark, legible down to 24pt.
        case threeCurl

        /// The small cut: same grid, same plate, the left curl removed.
        case twoCurl

        /// Axis positions of the unaccented curls, in units.
        var outerCurlAxes: [CGFloat] {
            switch self {
            case .twoCurl: [26.0]
            case .automatic, .threeCurl: [20.0, 44.0]
            }
        }

        /// Axis position of the accented curl, in units.
        var middleCurlAxis: CGFloat {
            switch self {
            case .twoCurl: 38.0
            case .automatic, .threeCurl: 32.0
            }
        }

        /// Where the plate begins, in units.
        var plateStart: CGFloat {
            switch self {
            case .twoCurl: 22.0
            case .automatic, .threeCurl: 18.0
            }
        }

        /// Where the plate ends, in units.
        var plateEnd: CGFloat {
            switch self {
            case .twoCurl: 42.0
            case .automatic, .threeCurl: 46.0
            }
        }
    }

    /// A pairing of colors for the mark.
    public enum Colorway: Sendable, Hashable {
        /// ``primary`` on a light color scheme, ``reversed`` on a dark one.
        case automatic

        /// Black steam and plate, accent middle curl, for light grounds.
        case primary

        /// Black throughout, for print, stamps, and single-ink production.
        case mono

        /// White steam and plate, accent middle curl, for dark grounds.
        case reversed

        /// Black with a white middle curl, for an accent ground.
        case onAccent

        /// The accent throughout, for decorative surfaces.
        case allAccent

        /// The surrounding `foregroundStyle`, for all curls and the plate alike.
        case inherited
    }

    /// The size at and above which the three-curl cut holds together.
    private static let threeCurlFloor: CGFloat = 24.0

    @Environment(\.colorScheme) private var colorScheme

    private let colorway: Colorway
    private let cut: Cut
    private let size: CGFloat

    /// Creates a mark.
    ///
    /// - Parameters:
    ///   - colorway: The colors to draw it in.
    ///   - size: The edge of the 64-unit grid in points, clearspace included.
    ///   - cut: Which cut to draw.
    public init(
        _ colorway: Colorway = .automatic,
        size: CGFloat = 64.0,
        cut: Cut = .automatic
    ) {
        self.colorway = colorway
        self.size = size
        self.cut = cut
    }

    public var body: some View {
        ZStack {
            strokedPart(.outerCurls, in: base)

            strokedPart(.plate, in: base)

            strokedPart(.middleCurl, in: accent)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Sous"))
        .accessibilityAddTraits(.isImage)
    }

    /// One part of the mark, stroked in `color`, or in the surrounding foreground style where it is
    /// `nil`.
    @ViewBuilder
    private func strokedPart(_ part: SousMarkShape.Part, in color: Color?) -> some View {
        let shape = SousMarkShape(part: part, cut: resolvedCut)
        let stroke = SousMarkShape.strokeStyle(size: size)

        if let color {
            shape.stroke(color, style: stroke)
        } else {
            shape.stroke(style: stroke)
        }
    }

    /// The cut drawn, once ``Cut/automatic`` is settled against `size` and the color scheme.
    var resolvedCut: Cut {
        switch cut {
        case .threeCurl, .twoCurl:
            return cut
        case .automatic:
            // Dark takes the two-curl cut at the floor, light only below it.
            let holds = colorScheme == .dark
                ? size > Self.threeCurlFloor
                : size >= Self.threeCurlFloor
            return holds ? .threeCurl : .twoCurl
        }
    }

    /// The colorway drawn, once ``Colorway/automatic`` is settled against the color scheme.
    var resolvedColorway: Colorway {
        switch colorway {
        case .automatic: colorScheme == .dark ? .reversed : .primary
        case .primary, .mono, .reversed, .onAccent, .allAccent, .inherited: colorway
        }
    }

    /// The color of the outer curls and the plate, or `nil` where they take the surrounding
    /// foreground style.
    private var base: Color? {
        switch resolvedColorway {
        case .primary, .mono, .onAccent: .black
        case .reversed: .white
        case .allAccent: .accent
        case .automatic, .inherited: nil
        }
    }

    /// The color of the middle curl, or `nil` where it takes the surrounding foreground style.
    private var accent: Color? {
        switch resolvedColorway {
        case .primary, .reversed, .allAccent: .accent
        case .mono: .black
        case .onAccent: .white
        case .automatic, .inherited: nil
        }
    }
}

#Preview("Colorways") {
    HStack(spacing: SousSpacing.large) {
        SousMark(.primary, size: 72.0)

        SousMark(.mono, size: 72.0)

        SousMark(.reversed, size: 72.0)
            .background(.black)

        SousMark(.onAccent, size: 72.0)
            .background(.accent)

        SousMark(.allAccent, size: 72.0)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.white)
}

#Preview("Down the sizes") {
    HStack(alignment: .bottom, spacing: SousSpacing.medium) {
        ForEach([112.0, 80.0, 56.0, 40.0, 32.0, 24.0, 20.0, 16.0], id: \.self) { size in
            SousMark(size: size)
        }
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.groupedBackground)
}
