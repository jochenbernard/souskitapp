# Pipeline tools

Scripts every pipeline agent starts from instead of writing its own. Each prints its usage when run without arguments and writes only where its output folder argument points; those that drive a simulator take its UDID first. Copy one to your scratch folder before changing it, and name a change worth keeping in your report.

## sim.sh

Boots and cleans up one simulator, and refuses to boot it unless it is muted.

```
sim.sh <udid> boot && sim.sh <udid> fresh "$APP" && sim.sh <udid> launch "$APP" nl-BE
```

Also `size`, `appearance`, `reset`, `shot`, `uninstall`, `shutdown`, and `down "$APP"` for the whole cleanup, VoiceOver included. `SIMCTL_CHILD_<NAME>=value` in the environment of `launch` reaches the app as `<NAME>`. It never mutes: after `simctl erase`, run `../mute-simulators.sh` while the simulator is shut down.

## build.sh

Builds, tests and lints a source folder the way the pipeline does.

```
build.sh build <source dir> <scratch>/dd      # prints the .app path
build.sh test  <source dir> <scratch>/dd-test <udid>
build.sh lint  <source dir> <changed file>...
```

`test` boots the simulator through `sim.sh`, so an unmuted one stops it, and deletes the `SousKitAppLibrary/Package.resolved` the run leaves behind. The full output lands in `build.log` or `test.log` in the derived data folder. One build at a time on the Mac.

## tap.sh

Taps a point or a labelled element with a real touch down and up.

```
WAIT=10 tap.sh <udid> 'Start cooking'
```

A label matches exactly, `^` starts a prefix, `KEY=AXUniqueId` matches the identifier, and the last match wins, since a presented screen's elements follow those under it. An element beyond the window's edge is scrolled into reach first; one hidden under a bar is not, and the bar takes the tap. Exit 2 means the touch stalled with the finger down, which repeats a stepper for as long as it lasts: discard that measurement. `OFFX` and `OFFY` take `ipad-window.sh origin`.

## sweep-text-sizes.sh

Captures one state at each text size: screenshot, `axe describe-ui` dump and frames.

```
SHEET=1 sweep-text-sizes.sh <udid> <out dir> core "sous-app.sh \$UDID en new-timer" "sous-app.sh \$UDID en cancel"
```

`all` is the 12 sizes, `core` is large, accessibility-medium and the largest, or name sizes yourself. The first command runs before each capture and the second after it. `SHEET=1` measures the open sheet against its own edges. It leaves the text size at large.

## frames.py

Prints or compares the frames of labelled elements in `axe describe-ui` dumps.

```
frames.py before.json after.json --tolerance 0.5
```

One dump lists every labelled element, button and field; `--sheet` keeps the open sheet and flags what passes its edges; `--center` prints a point to tap; `--window` the window's size. Two dumps print what moved, with countdowns and the clock masked, and exit 1 on a difference. Frames inside a floating iPhone sheet are 0.96 of the sheet's own points; with the keyboard up, and on a full-screen iPad, they are 1:1.

## compare-pixels.py

Counts the pixels that differ between two screenshots, with the bands they lie in.

```
compare-pixels.py before.png after.png --crop 0,190,1206,2300 --control before-again.png
```

Exit 0 means identical. `--control` takes a second shot of the same state on the first build and reports that difference first: a build already differs from itself in the home indicator and a few pixels of glass. Crop out the status bar, whose clock changes. `--scale 2` for an iPad. It needs `ffmpeg`.

## record-frames.sh

Records the screen while a command runs, then cuts the recording into frames.

```
TILE=8x3 FPS=20 record-frames.sh <udid> <out dir> sous-app.sh <udid> en new-timer cancel
```

Without `FPS` it keeps every frame the screen changed in, with each frame's time in `times.txt`; the recorder writes none while nothing moves. `FROM`, `LENGTH` and `CROP` cut a part, and `TILE` writes contact sheets. It stops only the recorder it started. For a fast case, slow the springs in a scratch build or start a second AXe process with `--pre-delay`.

## ipad-window.sh

Resizes and tiles the app's iPad window and puts it back to full screen.

```
ipad-window.sh <udid> width 375 && ipad-window.sh <udid> origin
```

`width` makes a centred window by dragging its corner, `tile left|right` and `full` go through the menu of the window's controls, and `mode` picks Stage Manager, Full Screen Apps or Windowed Apps in Settings. The narrowest window is 375 points. It cannot set a height, move a window, tile to the top or bottom, or make Split View or Slide Over, and it only knows windows that start at the top of the screen. Where the app draws a button under the window's controls, the menu's hold can reach that button. A reinstalled app opens in the window the last one was left in, so end on `full`.

## voiceover.sh

Switches VoiceOver on and off and reads what it says, without sound; `on` refuses an unmuted simulator.

```
voiceover.sh <udid> on && tap.sh <udid> brioche && voiceover.sh <udid> phrase
```

Under VoiceOver a touch moves its cursor; `next` and `previous` move it too. `phrase` copies the last spoken phrase, once per reading. `timeline <out dir> <command>` keeps VoiceOver's log while a command runs and reduces it to speech requests, received notifications and activations. `off` removes its preferences; `pause` keeps them. Nothing outside the simulator performs a double tap or a scrub: `activate`, `escape`, `cursor` and `tree` need a probe build (see patches). Trait words come in the simulator's own language (Knop), whatever the app's.

## patches

Scratch-only changes to the app's source: stand-in timers, and the in-process VoiceOver probe.

```
git -C <repo> archive <commit> | tar -x -C <scratch>/src && patches/apply-standin-timers.sh <scratch>/src
```

`apply-standin-timers.sh` swaps in a scheduler that needs no AlarmKit permission: timers in memory, silent, marked as ringing when over, gone on a relaunch. `SIMCTL_CHILD_SOUS_STANDIN_TIMERS=n` seeds n timers and `SIMCTL_CHILD_SOUS_STANDIN_LATE=s` starts one more after s seconds. `apply-ax-probe.sh` adds `AXDump.swift` and turns the lint plugin off; launch with `SIMCTL_CHILD_SOUS_AX_DUMP=1`. Both are tied to the app's current source, refuse a git checkout, and stop without changing anything when that source has changed shape. They are never committed to a ticket branch.

## sous-app.sh

The Sous app's own navigation, kept out of every other script.

```
sous-app.sh <udid> en mock "recipe:quiche lorraine" cook "timer:30 min"
```

Steps run in order: `mock`, `recipe:<name>`, `back`, `cook`, `timer:<label>`, `new-timer`, `cancel`, `scale`, `settings`, `done`, `stop`. Launch the app in the same language first. A relaunch comes back on the cooking screen with the recipe screen listed behind it, so `stop` before going elsewhere. Starting a timer needs a stand-in build.

## Traps

What cost earlier agents time, and what handles it.

- Real timers do not start on a simulator: its permission prompt never shows. Use a stand-in build; never edit a permission store.
- `axe type` sends hardware keys, and a simulator on the Belgian layout turns digits into punctuation. Read the field's value back, and use the steppers where it is wrong.
- AXe's input broker hangs under load, and a stalled touch holds a button down. `tap.sh` reports both, and with `RESTART_BROKER=1` restarts the simulator's own broker.
- A freshly opened sheet's glass bar buttons differ from run to run. Compare screenshots taken after a touch in the sheet, or with `--control`.
- The narrowest iPad window is 375 points.
- A test run writes `SousKitAppLibrary/Package.resolved`; `build.sh test` deletes it.
- `simctl spawn` needs an interrupt, not a plain kill, or what it spawned keeps running.
