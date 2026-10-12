#!/bin/bash
# Resizes and tiles the window of the app in front on an iPad simulator, and puts it back to full screen.
# Usage: ipad-window.sh <udid> <command> [arguments]
#   size                    the window's width and height in points
#   origin                  the window's place on the screen as "x y", which tap.sh takes as OFFX and OFFY
#   width <points>          a centred window that wide and as tall as the screen, by dragging its corner;
#                           375 is the narrowest
#   tile <left|right>       through the menu of the window's controls
#   full                    back to the whole screen, from a window or a tile
#   mode <windowed|stage-manager|full-screen>
#                           the multitasking mode, picked in the Settings app (Dutch or English)
# Needs Windowed Apps mode, the default, for everything but mode, and a window that starts at the top of the
# screen: one it made itself. Cannot set a height, move a window, tile to the top or bottom, make Split View
# or Slide Over, or rotate the device. A window left elsewhere is filled by hand: hold its controls, pick fill.
set -u

here=$(cd "$(dirname "$0")" && pwd)

usage() {
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
}

[ "$#" -ge 2 ] || usage
udid=$1
command=$2
shift 2

# window_size: "w h" of the app's window. Frames in the tree are relative to it, so its own frame starts at 0.
window_size() {
    axe describe-ui --udid "$udid" | python3 "$here/frames.py" - --window
}

# screen_size: "w h" of the screen in points.
screen_size() {
    xcrun simctl io "$udid" enumerate 2> /dev/null | awk -F '[{},:]' '
        /Pixel Size/ && !width { width = $3; height = $4 }
        /Preferred UI Scale/ && !scale { scale = $2 }
        END { printf "%d %d\n", width / scale, height / scale }'
}

is_full() {
    [ "$(window_size)" = "$(screen_size)" ]
}

# at <x> <y> <grabber|controls|menu>: the frame and label of what lies at a screen point, as "x y w h label", if
# it is the window's resize handle, the window's controls, or an option of the controls' menu, which is a
# button of that menu's cell size. Nothing for anything else, or for a point outside every window.
# The system's own elements, unlike the app's, answer with frames on the screen.
at() {
    axe describe-ui --point "$1,$2" --udid "$udid" 2> /dev/null | python3 -c '
import json, sys

def walk(node):
    yield node
    for child in node.get("children", []):
        yield from walk(child)

# A point on the controls answers as the controls, as a group holding their three dots, or as one dot. A dot
# is 6 points wide and lies this far into the controls, which are 41 by 22.
DOTS = {"Close-button": 7.25, "Minimize-button": 17.5, "Zoom-button": 27.75}

def frame(node, wanted):
    f, identifier = node["frame"], node.get("AXUniqueId") or ""
    if wanted == "grabber" and identifier == "resize-grabber":
        return f["x"], f["y"], f["width"], f["height"]
    if wanted == "controls" and identifier.startswith("window-controls"):
        return f["x"], f["y"], f["width"], f["height"]
    if wanted == "controls" and identifier in DOTS and f["width"] < 10:
        return f["x"] - DOTS[identifier], f["y"] - 8, 41, 22
    if wanted == "menu" and node.get("type") == "Button" and 50 <= f["width"] <= 57 and 48 <= f["height"] <= 55:
        return f["x"], f["y"], f["width"], f["height"]
    return None

try:
    found = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
for root in found if isinstance(found, list) else [found]:
    for node in walk(root):
        box = frame(node, sys.argv[1])
        if box:
            print(*(round(v) for v in box), node.get("AXLabel"))
            sys.exit(0)' "$3"
}

# controls: the frame of the window's controls on the screen, as "x y w h", for a window at the top of the screen
# that is centred or at either edge. A window that fills the screen has none.
controls() {
    read -r w _ <<< "$(window_size)"
    read -r sw _ <<< "$(screen_size)"
    for left in $(( (sw - w) / 2 )) 0 $(( sw - w )); do
        found=$(at $(( left + 38 )) 54 controls)
        if [ -n "$found" ]; then
            echo "$found" | cut -d ' ' -f 1-4
            return 0
        fi
    done
    return 1
}

# origin: the window's place on the screen as "x y". Its controls lie 21 points in from its leading edge.
origin() {
    if is_full; then
        echo "0 0"
        return 0
    fi
    found=$(controls) || {
        echo "no window at the top of the screen: is the iPad in Windowed Apps mode with the app in front?" >&2
        return 1
    }
    echo "$(( ${found%% *} - 21 )) 0"
}

# resize <width>: drags the handle in the window's bottom trailing corner sideways until the window is that wide.
# A centred window grows by twice the handle's travel, and an estimate that misses is corrected by the next drag.
resize() {
    attempt=0
    while [ "$attempt" -lt 5 ]; do
        attempt=$(( attempt + 1 ))
        read -r w h <<< "$(window_size)"
        dw=$(( $1 - w ))
        if [ "${dw#-}" -le 1 ]; then
            return 0
        fi
        place=$(origin) || return 1
        gx=$(( ${place% *} + w - 8 ))
        gy=$(( h - 8 ))
        if [ -z "$(at "$gx" "$gy" grabber)" ]; then
            echo "no resize handle in the window's corner: a tile has none there, so run full first" >&2
            return 1
        fi
        axe drag --start-x "$gx" --start-y "$gy" --end-x $(( gx + dw / 2 )) --end-y "$gy" \
            --steps 40 --duration 1.0 --udid "$udid" > /dev/null
        sleep 2.5
    done
    return 1
}

# menu <column> <row>: holds the window's controls until their menu shows and taps an option by its place in
# the grid, whatever the language: the first row starts with left and right, the second with fill.
menu() {
    found=$(controls) || {
        echo "no window controls: a window that fills the screen has none" >&2
        return 1
    }
    read -r x y _ <<< "$found"
    axe touch -x $(( x + 20 )) -y $(( y + 11 )) --down --udid "$udid" > /dev/null
    sleep 1
    axe touch -x $(( x + 20 )) -y $(( y + 11 )) --up --udid "$udid" > /dev/null
    sleep 3
    # The options are cells of 53.5 by 51.5 points, the first 8 points left of the controls and 67.5 below.
    option_x=$(( x + 19 + $1 * 107 / 2 ))
    option_y=$(( y + 93 + $2 * 79 ))
    option=$(at "$option_x" "$option_y" menu)
    if [ -z "$option" ]; then
        echo "the controls' menu did not open: the hold may have reached a button the app draws under the controls" >&2
        return 1
    fi
    axe touch -x "$option_x" -y "$option_y" --down --up --delay 0.08 --udid "$udid" > /dev/null
    sleep 3
    echo "picked \"$(echo "$option" | cut -d ' ' -f 5-)\""
}

case $command in
size)
    window_size
    ;;

origin)
    origin
    ;;

width)
    [ "$#" -eq 1 ] || usage
    resize "$1"
    reached=$?
    size=$(window_size)
    echo "$size"
    if [ "$reached" -ne 0 ]; then
        echo "the window came out ${size% *} wide, not $1 (the simulator's narrowest is 375)" >&2
        exit 1
    fi
    ;;

tile)
    [ "$#" -eq 1 ] || usage
    case $1 in
    left) column=0 ;;
    right) column=1 ;;
    *) usage ;;
    esac
    # A window that fills the screen has no controls, so it is made a window first.
    if is_full; then
        read -r sw _ <<< "$(screen_size)"
        resize $(( sw - 120 )) || exit 1
    fi
    menu "$column" 0 || exit 1
    echo "window $(window_size) at $(origin)"
    ;;

full)
    # Through the menu's fill, which works from a window and from a tile alike.
    is_full || menu 0 1 > /dev/null
    window_size
    is_full || { echo "the window does not fill the screen" >&2; exit 1; }
    ;;

mode)
    [ "$#" -eq 1 ] || usage
    case $1 in
    windowed) labels="Apps in vensters|Windowed Apps" ;;
    stage-manager) labels="Stage Manager" ;;
    full-screen) labels="Schermvullende apps|Full Screen Apps" ;;
    *) usage ;;
    esac
    xcrun simctl launch "$udid" com.apple.Preferences > /dev/null
    sleep 4
    place=$(origin 2> /dev/null) || place="0 0"
    export OFFX=${place% *} OFFY=${place#* }
    WAIT=3 "$here/tap.sh" "$udid" "Multitasking en gebaren" 2> /dev/null \
        || WAIT=3 "$here/tap.sh" "$udid" "Multitasking & Gestures" \
        || { echo "no multitasking settings found" >&2; exit 1; }
    sleep 2.5
    picked=1
    old_ifs=$IFS
    IFS='|'
    for label in $labels; do
        if "$here/tap.sh" "$udid" "$label" 2> /dev/null; then
            picked=0
            echo "picked \"$label\""
            break
        fi
    done
    IFS=$old_ifs
    sleep 2.5
    xcrun simctl terminate "$udid" com.apple.Preferences > /dev/null 2>&1
    [ "$picked" -eq 0 ] || { echo "no such mode in the Settings app" >&2; exit 1; }
    ;;

*)
    usage
    ;;
esac
