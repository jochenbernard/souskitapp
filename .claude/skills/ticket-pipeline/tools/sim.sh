#!/bin/bash
# Boots, sets up and cleans up one simulator, and refuses to boot it unless it is muted.
# Usage: sim.sh <udid> <command> [arguments]
#   muted                        succeeds only if the simulator's sound goes to the silent device
#   boot                         boots it (only when muted) and waits until it is up
#   install <app path>           installs a build over the installed one
#   fresh <app path>             uninstalls first, so the app starts without its data
#   launch <app path|bundle id> [language] [launch arguments]
#                                relaunches the app, in en or nl-BE when given; SIMCTL_CHILD_<NAME>=value
#                                in the environment reaches the app as <NAME>
#   size <content size>          the text size, such as large or accessibility-extra-extra-extra-large
#   appearance <light|dark>
#   reset                        text size large, appearance light
#   shot <file.png>              a full-size screenshot
#   uninstall <app path|bundle id>
#   shutdown
#   down <app path|bundle id>    the cleanup: VoiceOver off and forgotten, reset, uninstall, shutdown
set -u

here=$(cd "$(dirname "$0")" && pwd)

usage() {
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
}

[ "$#" -ge 2 ] || usage
udid=$1
command=$2
shift 2

audio="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/var/run/com.apple.coresimulator.audio.plist"

is_muted() {
    [ "$(plutil -extract useHostDefaultOutputDevice raw "$audio" 2> /dev/null)" = false ]
}

is_booted() {
    xcrun simctl list devices | grep -F "($udid)" | grep -q "(Booted)"
}

# bundle_id <app path|bundle id>
bundle_id() {
    if [ -d "$1" ]; then
        plutil -extract CFBundleIdentifier raw "$1/Info.plist"
    else
        echo "$1"
    fi
}

case $command in
muted)
    is_muted || { echo "$udid is NOT muted" >&2; exit 1; }
    echo "$udid is muted"
    ;;

boot)
    if ! is_muted; then
        echo "$udid is not muted: not booting it. Run $(dirname "$here")/mute-simulators.sh $udid while it is shut down." >&2
        exit 1
    fi
    is_booted || xcrun simctl boot "$udid" || exit 1
    xcrun simctl bootstatus "$udid" -b > /dev/null 2>&1
    is_booted || { echo "$udid did not boot" >&2; exit 1; }
    ;;

install)
    [ "$#" -eq 1 ] || usage
    xcrun simctl install "$udid" "$1"
    ;;

fresh)
    [ "$#" -eq 1 ] || usage
    bundle=$(bundle_id "$1")
    xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1
    xcrun simctl uninstall "$udid" "$bundle"
    xcrun simctl install "$udid" "$1"
    ;;

launch)
    [ "$#" -ge 1 ] || usage
    bundle=$(bundle_id "$1")
    shift
    language=()
    if [ "$#" -ge 1 ]; then
        language=(-AppleLanguages "($1)" -AppleLocale "$(echo "$1" | tr - _)")
        shift
    fi
    xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1
    xcrun simctl launch "$udid" "$bundle" ${language[@]+"${language[@]}"} "$@" > /dev/null
    ;;

size)
    [ "$#" -eq 1 ] || usage
    xcrun simctl ui "$udid" content_size "$1"
    ;;

appearance)
    [ "$#" -eq 1 ] || usage
    xcrun simctl ui "$udid" appearance "$1"
    ;;

reset)
    xcrun simctl ui "$udid" content_size large
    xcrun simctl ui "$udid" appearance light
    ;;

shot)
    [ "$#" -eq 1 ] || usage
    mkdir -p "$(dirname "$1")"
    xcrun simctl io "$udid" screenshot "$1" > /dev/null 2>&1 || { echo "no screenshot of $udid" >&2; exit 1; }
    ;;

uninstall)
    [ "$#" -eq 1 ] || usage
    bundle=$(bundle_id "$1")
    xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1
    xcrun simctl uninstall "$udid" "$bundle"
    ;;

shutdown)
    is_booted && xcrun simctl shutdown "$udid"
    exit 0
    ;;

down)
    [ "$#" -eq 1 ] || usage
    if is_booted; then
        bundle=$(bundle_id "$1")
        "$here/voiceover.sh" "$udid" off
        xcrun simctl ui "$udid" content_size large
        xcrun simctl ui "$udid" appearance light
        xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1
        xcrun simctl uninstall "$udid" "$bundle"
        xcrun simctl shutdown "$udid"
    fi
    echo "$udid: $(xcrun simctl list devices | grep -F "($udid)" | sed -E 's/.*\(([A-Za-z]+)\) *$/\1/')"
    ;;

*)
    usage
    ;;
esac
