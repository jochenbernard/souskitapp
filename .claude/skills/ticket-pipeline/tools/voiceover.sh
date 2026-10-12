#!/bin/bash
# Switches VoiceOver on and off in a muted simulator and reads what it says and does, without sound.
# Usage: voiceover.sh <udid> <command> [arguments]
#   on                       starts VoiceOver; refuses unless the simulator is muted
#   pause                    stops it but keeps what it stored, such as its introduction having been read
#   off                      stops it and removes its preferences (the cleanup)
#   status                   whether it is enabled and running
#   phrase                   the last phrase it spoke, through its "copy last phrase" command
#   next [n] | previous [n]  moves its cursor n elements on or back
#   moves <seconds>          the elements its cursor left in the last seconds, from its own log
#   timeline <out dir> <command> [arguments]
#                            its log while the command runs (<out dir>/vot.log), reduced to what it sent to
#                            speech, the notifications it received and its activations
#   reduce <vot.log>         the same reduction of a log kept earlier
# Only in a build with patches/apply-ax-probe.sh, launched with SIMCTL_CHILD_SOUS_AX_DUMP=1:
#   tree                     the accessibility tree UIKit holds, the one VoiceOver walks
#   cursor                   the element VoiceOver is on
#   activate                 activates that element, as a double tap does
#   escape                   performs VoiceOver's escape, as a two finger scrub does
set -u

usage() {
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
}

[ "$#" -ge 2 ] || usage
udid=$1
command=$2
shift 2

audio="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/var/run/com.apple.coresimulator.audio.plist"

in_sim() {
    xcrun simctl spawn "$udid" "$@"
}

enabled() {
    [ "$(in_sim defaults read com.apple.Accessibility VoiceOverTouchEnabled 2> /dev/null)" = 1 ]
}

running() {
    in_sim launchctl list 2> /dev/null | awk '$3 == "com.apple.VoiceOverTouch" && $1 != "-"' | grep -q .
}

stop() {
    in_sim defaults write com.apple.Accessibility VoiceOverTouchEnabled -bool false
    in_sim notifyutil -p com.apple.accessibility.cache.vot
    in_sim launchctl stop com.apple.VoiceOverTouch
    sleep 3
}

# probe_lines <seconds> <predicate>: the probe's SOUSAX lines of the last seconds.
probe_lines() {
    in_sim log show --last "$1s" --style compact --predicate "$2" 2> /dev/null | grep -a -o 'SOUSAX.*'
}

# tree: asks the probe for a dump and prints the last whole one. The log trails on a busy machine, so it retries.
tree() {
    axe describe-ui --udid "$udid" > /dev/null 2>&1
    attempt=0
    while [ "$attempt" -lt 4 ]; do
        attempt=$(( attempt + 1 ))
        in_sim notifyutil -p sous.axdump
        sleep 1.5
        dump=$(probe_lines 6 'eventMessage BEGINSWITH "SOUSAX"' \
            | awk '/SOUSAX-BEGIN/ { buffer = "" } { buffer = buffer $0 "\n" } /SOUSAX-END/ { last = buffer } END { printf "%s", last }')
        if [ -n "$dump" ]; then
            echo "$dump"
            return 0
        fi
    done
    echo "no dump: is this a probe build launched with SIMCTL_CHILD_SOUS_AX_DUMP=1?" >&2
    return 1
}

# asked <notification> <line prefix>: posts a notification to the probe and prints the line it logged for it.
asked() {
    in_sim notifyutil -p "$1"
    sleep 2
    line=$(probe_lines 5 "eventMessage BEGINSWITH \"$2\"" | tail -1)
    if [ -z "$line" ]; then
        echo "no $2 line: is this a probe build launched with SIMCTL_CHILD_SOUS_AX_DUMP=1?" >&2
        return 1
    fi
    echo "$line"
}

reduce() {
    python3 - "$1" <<'EOF'
import re
import sys

head = re.compile(r"^\d{4}-\d\d-\d\d (\d\d:\d\d:\d\d\.\d+) +\w+ +(\S+?)\[[^\]]*\] (.*)$")
keep = re.compile(r"OutputRequest|Received note|SOUSAX-A|SOUSAX-FOCUS|SOUSAX-ESCAPE|Resolved command: 'VOS"
                  r"|Tapping callback|simple tap|[Aa]ctivat|Announc|Speaking|speak")
drop = re.compile(r"coreaudio|defaults|IdleTimer|launchservices|CFBundle|xpc:connection|de-activate delay"
                  r"|Deactivating AudioServices|[Ss]ession deactivat|Should not speak for incoming call")
messages = []
for raw in open(sys.argv[1], errors="replace"):
    raw = raw.rstrip("\n")
    match = head.match(raw)
    if match:
        messages.append([match.group(1), match.group(2), match.group(3)])
    elif messages:
        messages[-1][2] += " / " + raw.strip()
last = None
for time, process, text in messages:
    if drop.search(text) or not keep.search(text):
        continue
    text = re.sub(r" resolver: .*", "", re.sub(r"0x[0-9a-f]+", "0x..", text))
    if text != last:
        print(time, process, text[:330])
    last = text
EOF
}

case $command in
on)
    if [ "$(plutil -extract useHostDefaultOutputDevice raw "$audio" 2> /dev/null)" != false ]; then
        echo "$udid is not muted: VoiceOver stays off. It speaks through the Mac's speakers." >&2
        exit 1
    fi
    # Read already, so VoiceOver's introduction to its gestures does not cover the app.
    in_sim defaults write com.apple.Accessibility VoiceOverTouchUserHasReadNoHomeButtonGestureDescription -bool true
    in_sim defaults write com.apple.Accessibility VoiceOverTouchEnabled -bool true
    in_sim notifyutil -p com.apple.accessibility.cache.vot
    in_sim launchctl start com.apple.VoiceOverTouch
    waited=0
    until running || [ "$waited" -ge 20 ]; do
        sleep 1
        waited=$(( waited + 1 ))
    done
    running || { echo "VoiceOver did not start. A simulator that never ran it needs one reboot first." >&2; exit 1; }
    sleep 5
    ;;

pause)
    stop
    ;;

off)
    stop
    for key in $(in_sim defaults read com.apple.Accessibility 2> /dev/null \
        | grep -o -i -E '"?[A-Za-z]*(VoiceOver|VOT)[A-Za-z]*"?' | tr -d '"' | sort -u); do
        in_sim defaults delete com.apple.Accessibility "$key" 2> /dev/null
    done
    in_sim notifyutil -p com.apple.accessibility.cache.vot
    left=$(in_sim defaults read com.apple.Accessibility 2> /dev/null | grep -c -i -E 'VoiceOver|VOT')
    echo "VoiceOver off, $left of its preferences left"
    ;;

status)
    enabled && echo "enabled" || echo "not enabled"
    running && echo "running" || echo "not running"
    ;;

phrase)
    # One copy per reading: a second one would copy VoiceOver's own confirmation of the first.
    echo "nothing copied" | xcrun simctl pbcopy "$udid"
    axe key-combo --modifiers 224,226,225 --key 6 --udid "$udid" > /dev/null
    waited=0
    phrase="nothing copied "
    while [ "$phrase" = "nothing copied " ] && [ "$waited" -lt 24 ]; do
        sleep 0.5
        waited=$(( waited + 1 ))
        phrase=$(xcrun simctl pbpaste "$udid" | tr '\n' ' ')
    done
    # Lets VoiceOver finish its confirmation before anything else happens.
    sleep 2.5
    if [ "$phrase" = "nothing copied " ]; then
        echo "nothing copied: VoiceOver is off or has not spoken" >&2
        exit 1
    fi
    echo "$phrase"
    ;;

next | previous)
    key=79
    [ "$command" = previous ] && key=80
    count=${1:-1}
    while [ "$count" -gt 0 ]; do
        axe key-combo --modifiers 224,226 --key "$key" --udid "$udid" > /dev/null
        sleep 1.2
        count=$(( count - 1 ))
    done
    ;;

moves)
    [ "$#" -eq 1 ] || usage
    # Debug lines of VoiceOver live only briefly: read them right after the moves.
    in_sim log show --last "$1s" --info --debug --style compact \
        --predicate 'process == "vot" AND eventMessage CONTAINS "ElementMovement decision"' 2> /dev/null \
        | grep -v Timestamp \
        | sed -E 's/.*current=//; s/VOTElement 0x[0-9a-f]+ \{ <AXUIElement: 0x[0-9a-f]+> \} //; s/ finger=.*//'
    ;;

timeline)
    [ "$#" -ge 2 ] || usage
    mkdir -p "$1"
    log=$(cd "$1" && pwd)/vot.log
    shift
    # Started directly, not through a function: the interrupt below has to reach simctl itself, which hands it
    # on to the log stream it spawned. A plain kill leaves that stream running.
    xcrun simctl spawn "$udid" log stream --level debug --style compact \
        --predicate 'process == "vot" OR eventMessage BEGINSWITH "SOUSAX"' > "$log" 2>&1 &
    stream=$!
    trap 'kill -INT "$stream" 2> /dev/null' EXIT
    sleep 3
    "$@"
    status=$?
    sleep 2
    kill -INT "$stream" 2> /dev/null
    wait "$stream" 2> /dev/null
    trap - EXIT
    reduce "$log"
    exit "$status"
    ;;

reduce)
    [ "$#" -eq 1 ] || usage
    reduce "$1"
    ;;

tree)
    tree
    ;;

cursor)
    tree | head -1 | sed 's/SOUSAX-BEGIN //'
    ;;

activate)
    asked sous.axactivate SOUSAX-ACTIVATE
    ;;

escape)
    asked sous.axescape SOUSAX-ESCAPE
    ;;

*)
    usage
    ;;
esac
