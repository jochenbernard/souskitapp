#!/bin/bash
# Taps a point or a labelled element with a real touch down and up, and notices a touch that stalled.
# Usage: tap.sh <udid> <x> <y>               a point, in the window's coordinates
#        tap.sh <udid> <label> [index]       the centre of the element with that label; ^ starts a prefix,
#                                            index picks among several (default -1, the last: the screen on top);
#                                            two numbers always read as a point
# Environment: KEY=AXUniqueId matches the identifier instead of the label; WAIT=<seconds> waits for the
# element; HOLD=<seconds> keeps the finger down; OFFX and OFFY are the origin of an iPad window that does
# not fill the screen (ipad-window.sh origin). A labelled element beyond the window's upper or lower edge is
# scrolled into reach first (NOSCROLL=1 taps it where it is); one under a bar is not, and the bar takes the tap.
# RESTART_BROKER=1 stops AXe's input broker of this simulator when it no longer takes a touch, and tries again:
# set it only for a simulator no other agent uses.
# Exit 1: no such element, or the touch was not sent. Exit 2: the touch stalled with the finger down.
set -u

here=$(cd "$(dirname "$0")" && pwd)

if [ "$#" -lt 2 ]; then
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

udid=$1
shift

is_number() {
    case $1 in
    '' | *[!0-9.-]*) return 1 ;;
    *) return 0 ;;
    esac
}

if [ "$#" -eq 2 ] && is_number "$1" && is_number "$2"; then
    x=$1
    y=$2
else
    tries=$(( ${WAIT:-0} * 2 + 1 ))
    scrolls=8
    while :; do
        dump=$(axe describe-ui --udid "$udid" 2> /dev/null)
        point=$(echo "$dump" \
            | python3 "$here/frames.py" - --center "$1" --key "${KEY:-AXLabel}" --index "${2:--1}" 2> /dev/null)
        if [ -z "$point" ]; then
            tries=$(( tries - 1 ))
            if [ "$tries" -le 0 ]; then
                echo "no element with ${KEY:-AXLabel} $1" >&2
                exit 1
            fi
            sleep 0.5
            continue
        fi
        x=${point% *}
        y=${point#* }

        # An element beyond the window's edge is scrolled into reach first: a touch there lands on something else.
        window=$(echo "$dump" | python3 "$here/frames.py" - --window)
        middle=$(( ${window% *} / 2 + ${OFFX:-0} ))
        height=${window#* }
        if [ -n "${NOSCROLL:-}" ] || [ "$scrolls" -le 0 ]; then
            break
        elif [ "$y" -ge $(( height - 10 )) ]; then
            from=$(( height * 2 / 3 ))
            to=$(( height / 3 ))
        elif [ "$y" -le 10 ]; then
            from=$(( height / 3 ))
            to=$(( height * 2 / 3 ))
        else
            break
        fi
        scrolls=$(( scrolls - 1 ))
        axe swipe --start-x "$middle" --start-y $(( from + ${OFFY:-0} )) --end-x "$middle" --end-y $(( to + ${OFFY:-0} )) \
            --duration 0.5 --udid "$udid" > /dev/null
        sleep 1.5
    done
fi

x=$(( ${x%.*} + ${OFFX:-0} ))
y=$(( ${y%.*} + ${OFFY:-0} ))
hold=${HOLD:-0.08}
whole=${hold%.*}
limit=$(( ${whole:-0} + 5 ))

attempt=0
while [ "$attempt" -lt 3 ]; do
    attempt=$(( attempt + 1 ))
    SECONDS=0
    output=$(axe touch -x "$x" -y "$y" --down --up --delay "$hold" --udid "$udid" 2>&1)
    status=$?

    # A touch on a busy machine can hang between down and up, which holds a button for as long as it hangs.
    if [ "$SECONDS" -gt "$limit" ]; then
        echo "the touch at $x,$y STALLED: it took $SECONDS s, the finger may have been down all along. Discard what it measured." >&2
        exit 2
    fi
    [ "$status" -eq 0 ] && exit 0
    echo "$output" >&2

    # Only a touch that was never sent is tried again, once this simulator's input broker has been restarted.
    case $output in
    *"could not establish"*) ;;
    *) exit 1 ;;
    esac
    broker=$(pgrep -f "axe hid-broker --udid $udid" | head -1)
    [ -n "$broker" ] || exit 1
    if [ -z "${RESTART_BROKER:-}" ]; then
        echo "AXe's input broker for $udid (PID $broker) is stuck: stop that PID, or run again with RESTART_BROKER=1" >&2
        exit 1
    fi
    kill "$broker" 2> /dev/null
    sleep 3
done
exit 1
