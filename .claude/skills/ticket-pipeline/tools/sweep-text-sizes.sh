#!/bin/bash
# Captures one state of the app at each text size: a screenshot, the `axe describe-ui` dump and its frames.
# Usage: sweep-text-sizes.sh <udid> <out dir> <all|core|"size size..."> [command] [after command]
#   all   the 12 content sizes; core  large, accessibility-medium and the largest
#   command        run through sh at each size before the capture, such as opening a sheet
#   after command  run after the capture, such as closing it again
# Both commands see UDID, SIZE, NAME (such as 08-accessibility-medium) and OUT. SETTLE (default 2.5) is the
# wait in seconds after a size change and after the command. SHEET=1 measures the open sheet only.
# Lands in <out dir>/<NN>-<size>.png, .json and .txt, and leaves the text size at large.
set -u

here=$(cd "$(dirname "$0")" && pwd)

if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

all="extra-small small medium large extra-large extra-extra-large extra-extra-extra-large accessibility-medium accessibility-large accessibility-extra-large accessibility-extra-extra-large accessibility-extra-extra-extra-large"

udid=$1
mkdir -p "$2"
out=$(cd "$2" && pwd)
case $3 in
all) sizes=$all ;;
core) sizes="large accessibility-medium accessibility-extra-extra-extra-large" ;;
*) sizes=$3 ;;
esac
before=${4:-}
after=${5:-}
settle=${SETTLE:-2.5}
failed=0

for size in $sizes; do
    number=0
    index=0
    for known in $all; do
        index=$(( index + 1 ))
        [ "$known" = "$size" ] && number=$index
    done
    if [ "$number" -eq 0 ]; then
        echo "unknown text size $size" >&2
        failed=1
        continue
    fi
    name=$(printf '%02d' "$number")-$size

    xcrun simctl ui "$udid" content_size "$size"
    sleep "$settle"
    if [ -n "$before" ]; then
        if ! UDID=$udid SIZE=$size NAME=$name OUT=$out sh -c "$before"; then
            echo "== $name: THE COMMAND FAILED" >&2
            failed=1
        fi
        sleep "$settle"
    fi

    axe describe-ui --udid "$udid" > "$out/$name.json"
    xcrun simctl io "$udid" screenshot "$out/$name.png" > /dev/null 2>&1
    if [ -n "${SHEET:-}" ]; then
        python3 "$here/frames.py" "$out/$name.json" --sheet > "$out/$name.txt" || failed=1
        echo "== $name: $(head -1 "$out/$name.txt") | $(tail -2 "$out/$name.txt" | tr '\n' ' ')"
    else
        python3 "$here/frames.py" "$out/$name.json" > "$out/$name.txt"
        echo "== $name: $(wc -l < "$out/$name.txt" | tr -d ' ') elements"
    fi

    if [ -n "$after" ]; then
        if ! UDID=$udid SIZE=$size NAME=$name OUT=$out sh -c "$after"; then
            echo "== $name: THE AFTER COMMAND FAILED" >&2
            failed=1
        fi
    fi
done

xcrun simctl ui "$udid" content_size large
exit "$failed"
