import SwiftUI

/// The Sous mark.
///
/// `size` includes the mark's clearspace, so the mark takes no extra padding.
public struct SousMark: View {
    /// Which cut of the mark to draw.
    public enum Cut: Sendable, Hashable {
        /// The cut that holds together at the mark's size and in the color scheme.
        case automatic

        /// The full mark.
        case threeCurl

        /// The mark for small sizes.
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
        /// The colorway for the color scheme.
        case automatic

        /// For a light ground.
        case primary

        /// For print, stamps, and single-ink production.
        case mono

        /// For a dark ground.
        case reversed

        /// For an accent ground.
        case onAccent

        /// For a decorative surface.
        case allAccent

        /// The surrounding foreground style.
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
    ///   - size: The mark's width and height in points, clearspace included.
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
