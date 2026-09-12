# Sous design system

The Sous brand, expressed in Swift.

## Layers

| Layer | Type | Use |
| --- | --- | --- |
| Semantic color | `SousColor` | What products draw from. Seven tokens, light and dark. |
| Raw color | `SousPalette` | The brand values, for what the tokens do not cover. |
| Type | `SousTextStyle`, `.sousTextStyle(_:)` | The six-entry scale, at its specified line heights. |
| Faces | `SousFontFace` | Archivo and JetBrains Mono, bundled and self-registering. |
| Layout | `SousSpacing`, `SousRadius` | Spacing steps and corner radii. |
| Mark | `SousMark` | The logo, drawn on the 64-unit grid. |
| Components | `.sousPrimary`, `.sousSecondary`, `.sousQuiet` | The three button styles. |
| Page | `.sousPage()` | The ground a screen sits on, and the text token on it. |
| Containers | `.sousSurface(cornerRadius:)`, `.sousCallout()`, `SousActivityNote` | The card, the wash, the spinner. |
| Catalog | `SousCatalog` | Every token on one page. Run the app to see it. |

## Rules

- Draw from the semantic layer: `SousColor.text`, not `SousPalette.ink`. Dark is then a
  seven-line override and nothing else.
- A token reads the scheme it is drawn in, and is a `Color`, so it goes anywhere a style or a
  color does. Nothing reaches for `@Environment(\.colorScheme)` to pick a value.
- A screen takes `.sousPage()`, and a container sets the color its content is read in. Only text
  stepping away from what it sits in, a caption in `SousColor.textMuted`, names a color itself.
- Orange means live, here, or do. Not decoration, category, or mood. Past roughly 5% of a
  layout it has become decoration, and on a dark ground it reads a third brighter still.
- Flame carries dark text. Ink on Flame is 5.5; White on Flame is 3.5 and fails.
- Quantities, temperatures, and times take `.data` or `.eyebrow`. Everything else is Archivo.
- Archivo 600 is limited to the wordmark, lockups, and `.display`.
- One primary button per view.
- Set text with `.sousTextStyle(_:)`. It carries Dynamic Type, so size, line height, and
  tracking scale together up through the accessibility sizes. A face taken straight from
  `SousFontFace` is fixed: right for a lockup, wrong for body text.
- `.sousTextStyle(_:)` is on `Text`; `.sousFont(_:)` is on `View`. See below for why.
- Motion is spring only; no easing curves.

## What the two themes do not share

Dark is not light inverted, and three things change beyond the token values:

- **The mono faces drop a weight.** `.data` and `.eyebrow` are JetBrains Mono Medium on light
  and Regular on dark; light type on a dark ground gains apparent weight. `SousTextStyle`
  resolves this, so a call site needs no branch.
- **The mark's floor moves.** `Cut.automatic` holds three curls at 24pt on light and takes the
  two-curl cut there on dark, where light strokes thin out sooner.
- **The primary colorway swaps.** `Colorway.automatic` draws `primary` on light and `reversed`
  on dark, the primary cut of the dark theme.

## Why the type scale has two entry points

A block of n lines measures `n * natural + (n - 1) * lineSpacing`, where the brand wants
`n * lineHeight`. The shortfall is exactly one leading correction whatever n is, so it has to
be added once per text block. SwiftUI applies `font`, `tracking`, and `lineSpacing` through
the environment, reaching every descendant, but padding lands once on whatever it wraps.
There is no hook for per-descendant layout, and `Font` cannot carry an overridden line height,
so a single modifier cannot do both jobs.

Hence the split:

- `Text.sousTextStyle(_:)` adds the correction, and is on `Text` so it cannot reach a
  container. A stack of three `.body` texts wrapped in it would render 66pt where 81pt is
  correct; that is a compile error rather than a silent 15pt.
- `View.sousFont(_:)` sets face, size, and tracking and leaves the line box alone. Safe on
  anything, and the only option for text a `Text` does not carry: a `TextField`, a `Label`,
  a stack. Blocks set this way sit one correction short of their line height.

`sousButtonLabel(_:)` uses the corrected form, since a button label is one text block and
dropping the correction would take the control under the 44pt minimum target.

## Beyond the seven tokens

The brand fixes the semantic layer at seven tokens, and this package ships those seven. Three
roles it names have no token, and take a palette value directly:

- Long-form prose: `SousPalette.graphite` on light, `SousPalette.chalk` on dark, one step
  quieter than `SousColor.text`.
- Eyebrows and captions on dark: `SousPalette.smoke`. The `textMuted` token is Ash.
- The wash under highlighted rows and callouts: `SousPalette.scorch` on light,
  `SousPalette.sear` on dark. `.sousCallout()` draws it and sets `accentText` on what it holds,
  so a call site names none of the three.

## Chosen here, not given by the brand

The `SousSpacing` steps and the `SousRadius` values are read off the mark's grid, where 8 is
the stroke, 12 the curl pitch, and 64 the grid.

The button styles are mostly chosen here too. The brand gives Ink on Flame at 5.5, Ember for a
pressed link, Ember as a fill on dark, Paper on Ember at 5.3, and one primary action per view.
That covers the primary button at rest and nothing else. `.sousSecondary` and `.sousQuiet`, the
capsule outline, every padding, and all press behavior are ours.

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

Two brand states are missing: the Flame outline called Attention, over Sear on dark, and the
hover Ember is given for.

## Adding to it

Motion is spring only. Example and preview strings come from the Sous example recipes, with
the format's inline markers resolved: recipe titles, steps, and header fields, never invented
copy.

New symbols need a doc comment; `missing_docs` is on with the rest of `opt_in_rules: all`.
Comments follow the repository's documentation style guide. Run `SousCatalog` in both
appearances to check nothing has drifted.
