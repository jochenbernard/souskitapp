# Sous design system

The Sous brand, expressed in Swift, and the source of truth for it. What ships here is the
design. The design documents it was first read off are out of date, and where one of them
disagrees with this package, this package is right.

## Layers

| Layer | Type | Use |
| --- | --- | --- |
| Semantic color | `SousColor` | What products draw from. Seven tokens, light and dark. |
| Raw color | `SousPalette` | The values themselves, for what the tokens do not cover. |
| Type | SwiftUI's `Font.TextStyle` | `.largeTitle`, `.title`, `.title3`, `.body`, `.subheadline`, `.caption2`. |
| Layout | `SousSpacing`, `SousRadius` | Spacing steps and corner radii. |
| Mark | `SousMark` | The logo, drawn on the 64-unit grid. |
| Components | `.sousPrimary`, `.sousSecondary`, `.sousQuiet` | The three button styles. |
| Page | `.sousPage()` | The ground a screen sits on, and the text token on it. |
| Containers | `.sousSurface(_:)`, `.sousCallout()`, `SousActivityNote` | The card, the wash, the spinner. |
| Catalog | `SousCatalog` | Every token on one page. Run the app to see it. |

## Rules

- Draw from the semantic layer: `SousColor.text`, not `SousPalette.ink`. Dark is then a
  seven-line override and nothing else.
- A token reads the scheme it is drawn in, and is a `Color`, so it goes anywhere a style or a
  color does. Nothing reaches for `@Environment(\.colorScheme)` to pick a value.
- A screen takes `.sousPage()`, and a container sets the color its content is read in. Only text
  stepping away from what it sits in, a caption in `SousColor.textMuted`, names a color itself.
- A container of one line reads as a capsule, and holds that radius as a rounded rectangle
  where its text wraps, so the curve of a row or a callout is the same whatever it holds. The
  radius is half the height of one `.body` line inside the container's own vertical padding,
  taken through `@ScaledMetric` so it follows Dynamic Type.
- A page is padded `SousSpacing.large` horizontally and `SousSpacing.small` vertically. The
  padding sits on the content, not on `.sousPage()`, which a scroll view needs it to; anything
  else on the screen, a bottom bar included, takes the same two values so its edges line up.
- Orange means live, here, or do. Not decoration, category, or mood. Past roughly 5% of a
  layout it has become decoration, and on a dark ground it reads a third brighter still.
- Flame carries dark text. Ink on Flame is 5.5; White on Flame is 3.5 and fails.
- Set text with `.font(_:)` and a system text style. Six of them are in use: `.largeTitle` for
  a hero line, `.title` for a landing headline or a step group, `.title3` for a section
  heading, `.body` for copy and controls, `.subheadline` for quantities and metadata,
  `.caption2` for an eyebrow.
- A screen's title is its `.navigationTitle(_:)`, large by default, and is not drawn again in
  the content. Cooking is the one screen that takes `.inline`, where the step in front of the
  cook outranks the recipe's name.
- A fixed size, `.system(size:weight:)`, is for the wordmark and nothing else. It does not
  scale, which is right for a lockup and wrong for anything a reader reads.
- Semibold is limited to the wordmark.
- One primary button per view.
- Motion is spring only; no easing curves.

## The type is the system type

The scale was six entries of its own: Archivo and JetBrains Mono, bundled and self-registering,
at fixed sizes and line heights, with a modifier per entry that corrected each text block to its
line box. All of it is gone, and text takes a SwiftUI text style. The faces, the modifiers, and
the tests that held them to their line heights are in the history.

Dynamic Type now comes from the text style, so nothing here scales a size or measures a face.
A layout that needs the height of a line of text takes `@ScaledMetric(relativeTo:)`, as
`KitchenFeatureView` does for its row radius.

## What the two themes do not share

Dark is not light inverted, and two things change beyond the token values:

- **The mark's floor moves.** `Cut.automatic` holds three curls at 24pt on light and takes the
  two-curl cut there on dark, where light strokes thin out sooner.
- **The primary colorway swaps.** `Colorway.automatic` draws `primary` on light and `reversed`
  on dark, the primary cut of the dark theme.

## Beyond the seven tokens

The semantic layer is seven tokens. Three roles have no token, and take a palette value
directly:

- Long-form prose: `SousPalette.graphite` on light, `SousPalette.chalk` on dark, one step
  quieter than `SousColor.text`.
- Eyebrows and captions on dark: `SousPalette.smoke`. The `textMuted` token is Ash.
- The wash under highlighted rows and callouts: `SousPalette.scorch` on light,
  `SousPalette.sear` on dark. `.sousCallout()` draws it and sets `accentText` on what it holds,
  so a call site names none of the three.

## Where the rest of the values come from

The `SousSpacing` steps and the `SousRadius` values are read off the mark's grid, where 8 is
the stroke, 12 the curl pitch, and 64 the grid.

Color fixes the primary button at rest and no more: Ink on Flame at 5.5, Ember for a pressed
link, Ember as a fill on dark, Paper on Ember at 5.3, one primary action per view.
`.sousSecondary` and `.sousQuiet`, the capsule outline, every padding, and all press behavior
are decided in this package. A button is one `.body` line inside 12pt of vertical padding,
which clears the 44pt minimum target and grows from there with Dynamic Type.

`.sousPrimary` draws that Flame as a Liquid Glass tint, not a flat fill. Ink stays the label
color, and the 5.5 figure holds where the tint sits over the page ground.

The three styles are separate types rather than one carrying an emphasis: no call site picks an
emphasis at run time, and the primary differs in kind, not degree. What they share is in
`ButtonPress`, `ButtonPressBody`, and `sousButtonLabel(_:)`.

A press scales the control and changes no color. `.sousPrimary` is the exception: its
`interactive()` glass flexes under the finger, and a scale on top would be a second reaction
to one touch. Nothing defines a fill for a pressed button, and Ink on Ember is 3.37, so
darkening the fill would force the label to change color mid-press. Dimming fails as well:
only 0.9 opacity keeps Ink on Flame above 4.5, which reads as no feedback at all. The pressed
state also outlives the finger by up to `ButtonPress.minimumDown`, since a tap can end within
a frame of starting and would otherwise show nothing. On `.sousPrimary` that hold keeps the
release haptic off the press.

A callout draws its wash inside a Flame outline, which is Attention on a container. One state
is not built: the hover Ember is given for.

## Adding to it

Motion is spring only. Example and preview strings come from the Sous example recipes, with
the format's inline markers resolved: recipe titles, steps, and header fields, never invented
copy.

New symbols need a doc comment; `missing_docs` is on with the rest of `opt_in_rules: all`.
Comments follow the repository's documentation style guide. Run `SousCatalog` in both
appearances to check nothing has drifted.
