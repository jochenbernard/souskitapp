# Sous design system

The Sous brand, expressed in Swift, and the source of truth for it. What ships here is the
design. The design documents it was first read off are out of date, and where one of them
disagrees with this package, this package is right.

## Layers

| Layer | Type | Use |
| --- | --- | --- |
| Color | `Color+Accent`, `Color+System` | The accent and its wash, and the system colors SwiftUI has no name for. |
| Type | SwiftUI's `Font.TextStyle` | `.largeTitle`, `.title`, `.title3`, `.body`, `.subheadline`, `.caption2`. |
| Layout | `SousSpacing`, `SousRadius` | Spacing steps and corner radii. |
| Mark | `SousMark` | The logo, drawn on the 64-unit grid. |
| Components | `.sousPrimary`, `.sousSecondary`, `.sousQuiet`, `.sousBare`, `.sousChip(isSelected:)`, `.sous` | The three button styles, the button its label draws, the chip a cook chooses from a set, and the disclosure group style. |
| Page | `.sousPage()`, `.sousPagePadding()` | The ground a screen sits on, and the inset to its edges. |
| Containers | `.sousSurface(_:)`, `.sousRow()`, `.sousRowPadding()`, `.sousRowSurface()`, `SousRowGroup`, `.sousCallout()`, `.sousChip()`, `SousActivityNote` | The card, the row and its two halves, the rows that share one card, the wash, the chip, the spinner. |
| Layouts | `SousFlowLayout` | Rows that wrap, for a set of chips. |
| Catalog | `SousCatalog` | Every color, style, and component on one page. |

## Rules

- Every color but the accent is a system color, named at the call site and picked for its role
  rather than its value: `groupedBackground` for a page, `secondaryGroupedBackground` for a row
  or a card, `tertiaryFill` for a control or a chip, `separator` for a border or a shadow,
  `.primary` and `.secondary` for text. Dark comes with them, and nothing reaches for
  `@Environment(\.colorScheme)` to pick a value.
- A UIKit color is a static on `Color` in `Color+System`, so a call site never writes
  `Color(.x)`. It is repeated on `ShapeStyle`, as `.groupedBackground` is, unless SwiftUI
  already names a style after it: a second `.separator` there makes both ambiguous, so
  `Color.separator` stays on `Color` and a style position takes SwiftUI's `.separator`.
- A page is the ground a SwiftUI `List` draws, and a row or a card is a `List` row. The launch
  screen takes the same ground through `LaunchBackground`, a color set in the app's asset catalog
  that points at `systemGroupedBackgroundColor` rather than holding a value.
- The accent is `.accent`, not `Color.accentColor` or `.tint`, which a package preview resolves
  to blue. It matches `AccentColor` in the app's asset catalog, and `AccentTests` fails where the
  two drift apart.
- A lighter accent is the accent at a named opacity, never a value of its own, so one role takes
  one opacity everywhere. The names follow the system fills: `.quaternaryAccentFill` fills a
  large area that holds content, as `quaternarySystemFill` does, and washes the one chip chosen
  from a set.
- A screen takes `.sousPage()`, and a container sets the color its content is read in. Only text
  stepping away from what it sits in, a caption in `.secondary`, names a color itself.
- A container of one line reads as a capsule, and holds that radius as a rounded rectangle
  where its text wraps, so the curve of a row or a callout is the same whatever it holds. The
  radius is half the height of one `.body` line inside the container's own vertical padding,
  taken through `@ScaledMetric` so it follows Dynamic Type. Every other box takes the same radius,
  a card or the rows sharing one included, so a screen curves alike from edge to edge. They share
  it through `LineContainerRadius`, which `.sousRowSurface()` draws with.
- A page is padded `SousSpacing.large` horizontally and `SousSpacing.small` vertically, through
  `.sousPagePadding()`. The padding sits on the content, not on `.sousPage()`, which a scroll view
  needs it to; anything else on the screen, a bottom bar included, takes it too so its edges line
  up.
- The accent means live, here, or do. Not decoration, category, or mood. Past roughly 5% of a
  layout it has become decoration, and on a dark ground it reads a third brighter still.
- The accent is `oklch(0.64 0.20 40)`, which sRGB holds as `#EA5202`. A new accent is picked in
  OKLCH, then written to `Color+Accent`, `AccentColor`, and the app icon's `icon.json`, which takes
  it as 0.91765, 0.32157, 0.00784. It carries white text, at APCA Lc 69.
- Set text with `.font(_:)` and a system text style. Six of them are in use: `.largeTitle` for
  a hero line, `.title` for a landing headline, `.title3` for the step in front of the cook,
  `.body` for copy and controls, `.subheadline` for quantities and metadata, `.caption2` for
  an eyebrow.
- A screen's title is its `.navigationTitle(_:)`, large by default, and is not drawn again in
  the content. Cooking is the one screen that takes `.inline`, where the step in front of the
  cook outranks the recipe's name. A sheet takes `.inline` too, in a toolbar of its own that holds
  its actions: Done is a `.confirm` button, not a style from here.
- A fixed size, `.system(size:weight:)`, is for the wordmark and nothing else. It does not
  scale, which is right for a lockup and wrong for anything a reader reads.
- Semibold is limited to the wordmark.
- One primary button per view.
- Motion is spring only; no easing curves.

## The type is the system type

Text takes a SwiftUI text style, and Dynamic Type comes from it, so nothing here scales a size or
measures a face.
A layout that needs the height of a line of text takes `@ScaledMetric(relativeTo:)`, as
`LineContainerRadius` does for the radius of a row or a callout.

## What the two themes do not share

Dark is not light inverted, and two things change beyond the system colors:

- **The mark's floor moves.** `Cut.automatic` holds three curls at 24pt on light and takes the
  two-curl cut there on dark, where light strokes thin out sooner.
- **The primary colorway swaps.** `Colorway.automatic` draws `primary` on light and `reversed`
  on dark, the primary cut of the dark theme.

## Where the rest of the values come from

The `SousSpacing` steps and the `SousRadius` values are read off the mark's grid, where 8 is
the stroke, 12 the curl pitch, and 64 the grid.

Color fixes the primary button at rest and no more: white on the accent at Lc 69, one primary action
per view. `.sousSecondary` and `.sousQuiet`, the capsule outline, every padding, and all press
behavior are decided in this package. A button is one `.body` line inside 12pt of vertical
padding, which clears the 44pt minimum target and grows from there with Dynamic Type.

`.sousPrimary` draws that accent as a Liquid Glass tint, not a flat fill. White stays the label
color, and the Lc 69 figure holds where the tint sits over the page ground.

The three styles are separate types rather than one carrying an emphasis: no call site picks an
emphasis at run time, and the primary differs in kind, not degree. What they share is in
`ButtonPress`, `ButtonPressBody`, and `sousButtonLabel(_:)`. `.sousChip(isSelected:)` is the one
style that takes a value, since whether a chip is chosen is state rather than emphasis; it draws
the same chip as `.sousChip()` and presses as the others do. `.sousBare` draws nothing itself,
for a control its label draws in full, such as the mark a cook ticks a step off with. It presses
as the others do and taps as `.sousPrimary` does.

A press scales the control and changes no color. `.sousPrimary` is the exception: its
`interactive()` glass flexes under the finger, and a scale on top would be a second reaction
to one touch. Nothing defines a fill for a pressed button: dimming the accent past 0.8 opacity
over a light ground drops its white label under Lc 60, which reads as no feedback at all. The
pressed state also outlives the finger by up to `ButtonPress.minimumDown`, since a tap can end
within a frame of starting and would otherwise show nothing. On `.sousPrimary` that hold keeps
the release haptic off the press.

A callout draws `.quaternaryAccentFill` inside an accent outline, which is Attention on a
container, and sets `.accent` on what it holds, so a call site names neither.

A disclosure group takes `.sous` rather than the automatic style, which clips its content, a
surface's shadow included, and cannot inset its chevron to line up with what is on a surface.

## Adding to it

Motion is spring only. Example and preview strings come from the Sous example recipes, with
the format's inline markers resolved: recipe titles, steps, and header fields, never invented
copy.

New symbols need a doc comment; `missing_docs` is on with the rest of `opt_in_rules: all`.
Comments follow the repository's documentation style guide. Run `SousCatalog` in both
appearances to check nothing has drifted.
