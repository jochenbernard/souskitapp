#!/bin/bash
# Adds the in-process VoiceOver probe (AXDump.swift) to a scratch copy of the app's source.
# Usage: apply-ax-probe.sh <source dir>     (a `git archive` copy, never a worktree)
# The built app starts the probe when launched with SIMCTL_CHILD_SOUS_AX_DUMP=1; read it with ../voiceover.sh.
set -u

here=$(cd "$(dirname "$0")" && pwd)

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

source_dir=$(cd "$1" && pwd)

if git -C "$source_dir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "$source_dir is a git checkout: the probe only goes into a git archive copy." >&2
    exit 1
fi

python3 - "$source_dir/SousKitAppLibrary" "$here/AXDump.swift" <<'EOF'
import pathlib
import shutil
import sys

library, probe = pathlib.Path(sys.argv[1]), sys.argv[2]
package = library / "Package.swift"
app = library / "Sources/AppFeature/SousKitApp.swift"

# Each: the file, the one place in it that is replaced, and what replaces it.
edits = [
    # No lint in the scratch build, so the probe's code cannot fail it.
    (package, """        [
            .plugin(
                name: "SwiftLintBuildToolPlugin",
                package: "SwiftLintPlugins"
            )
        ]""", "        []"),
    (app, "    public init() {}", """    public init() {
        if ProcessInfo.processInfo.environment["SOUS_AX_DUMP"] != nil {
            AXDump.start()
        }
    }"""),
]

texts = {}
for path, old, _ in edits:
    if not path.is_file():
        sys.exit(f"CHANGED SHAPE: {path} is gone. Nothing changed; update apply-ax-probe.sh.")
    texts[path] = path.read_text()
    if texts[path].count(old) != 1:
        sys.exit(f"CHANGED SHAPE: {path} holds this {texts[path].count(old)} times, not once:\n{old}\n"
                 "Nothing changed; update apply-ax-probe.sh.")

for path, old, new in edits:
    path.write_text(texts[path].replace(old, new))
shutil.copy(probe, app.parent / "AXDump.swift")
print(f"probe in {app.parent / 'AXDump.swift'}, started by {app.name}, lint plugin off")
EOF
