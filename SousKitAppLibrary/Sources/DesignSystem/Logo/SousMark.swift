import SwiftUI

/// The Sous mark: curls of steam over a plate, drawn on a 64-unit grid.
///
/// `size` is the edge of that grid, and the grid carries the mark's clearspace. The mark
/// takes no extra padding.
public struct SousMark: View {
    /// Which cut of the mark to draw.
    public enum Cut: Sendable, Hashable, CaseIterable {
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
    public enum Colorway: Sendable, Hashable, CaseIterable {
        /// ``primary`` on a light color scheme, ``reversed`` on a dark one.
        case automatic

        /// Ink steam and plate, Flame middle curl, for Paper grounds.
        case primary

        /// Ink throughout, for print, stamps, and single-ink production.
        case mono

        /// Paper steam and plate, Flame middle curl, for Ink and other dark grounds.
        case reversed

        /// Ink with a White middle curl, for a Flame ground.
        case onFlame

        /// Flame throughout, for decorative surfaces.
        case allFlame

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
        let stroke = StrokeStyle(
            lineWidth: SousMarkShape.strokeWidth * size / SousMarkShape.gridSize,
            lineCap: .round,
            lineJoin: .round
        )
        let resolved = resolvedCut

        ZStack {
            SousMarkShape(part: .outerCurls, cut: resolved)
                .stroke(base, style: stroke)

            SousMarkShape(part: .plate, cut: resolved)
                .stroke(base, style: stroke)

            SousMarkShape(part: .middleCurl, cut: resolved)
                .stroke(accent, style: stroke)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Sous"))
        .accessibilityAddTraits(.isImage)
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
        case .primary, .mono, .reversed, .onFlame, .allFlame, .inherited: colorway
        }
    }

    /// The stroke for the outer curls and the plate.
    private var base: AnyShapeStyle {
        switch resolvedColorway {
        case .primary, .mono, .onFlame: AnyShapeStyle(SousPalette.ink)
        case .reversed: AnyShapeStyle(SousPalette.paper)
        case .allFlame: AnyShapeStyle(SousPalette.flame)
        case .automatic, .inherited: AnyShapeStyle(.foreground)
        }
    }

    /// The stroke for the middle curl.
    private var accent: AnyShapeStyle {
        switch resolvedColorway {
        case .primary, .reversed, .allFlame: AnyShapeStyle(SousPalette.flame)
        case .mono: AnyShapeStyle(SousPalette.ink)
        case .onFlame: AnyShapeStyle(SousPalette.white)
        case .automatic, .inherited: AnyShapeStyle(.foreground)
        }
    }
}

#Preview("Colorways") {
    HStack(spacing: SousSpacing.large) {
        SousMark(.primary, size: 72.0)

        SousMark(.mono, size: 72.0)

        SousMark(.reversed, size: 72.0)
            .background(SousPalette.ink)

        SousMark(.onFlame, size: 72.0)
            .background(SousPalette.flame)

        SousMark(.allFlame, size: 72.0)
    }
    .padding(SousSpacing.xLarge)
    .background(SousPalette.paper)
}

#Preview("Down the sizes") {
    HStack(alignment: .bottom, spacing: SousSpacing.medium) {
        ForEach([112.0, 80.0, 56.0, 40.0, 32.0, 24.0, 20.0, 16.0], id: \.self) { size in
            SousMark(size: size)
        }
    }
    .padding(SousSpacing.xLarge)
    .background(SousPalette.paper)
}
