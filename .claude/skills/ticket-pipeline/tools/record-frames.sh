#!/bin/bash
# Records the simulator's screen while a command runs, then cuts the recording into frames.
# Usage: record-frames.sh <udid> <out dir> <command> [arguments]
# Environment: FPS=<n> resamples to n frames a second (default: every frame the screen changed in);
# FROM=<seconds> and LENGTH=<seconds> cut a part; CROP=w:h:x:y in pixels; TILE=<columns>x<rows> writes
# contact sheets in place of single frames, each frame WIDTH pixels wide (default 220).
# Lands in <out dir>/recording.mp4, frames/NNNN.png and times.txt (each frame's time in the recording).
# Stops only the recorder it started.
set -u

if [ "$#" -lt 3 ]; then
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

udid=$1
mkdir -p "$2/frames"
out=$(cd "$2" && pwd)
shift 2

video=$out/recording.mp4
rm -f "$video" "$out"/frames/*.png

xcrun simctl io "$udid" recordVideo --codec h264 --force "$video" > "$out/recorder.log" 2>&1 &
recorder=$!
stop_recorder() {
    kill -INT "$recorder" 2> /dev/null
    wait "$recorder" 2> /dev/null
}
trap stop_recorder EXIT

# The recorder says when it has started; the command must not run before.
waited=0
until grep -q "Recording started" "$out/recorder.log" 2> /dev/null || [ "$waited" -ge 40 ]; do
    sleep 0.25
    waited=$(( waited + 1 ))
done
if ! kill -0 "$recorder" 2> /dev/null; then
    cat "$out/recorder.log" >&2
    echo "the recording did not start" >&2
    exit 1
fi

"$@"
status=$?
sleep 1
stop_recorder
trap - EXIT

if [ ! -s "$video" ]; then
    echo "no recording at $video" >&2
    exit 1
fi

cut=()
[ -n "${FROM:-}" ] && cut+=(-ss "$FROM")
[ -n "${LENGTH:-}" ] && cut+=(-t "$LENGTH")

filters=
add_filter() {
    filters=${filters:+$filters,}$1
}
# The recorder writes a frame only when the screen changes, so without a rate every frame is kept as it is.
mode=(-fps_mode passthrough)
if [ -n "${FPS:-}" ]; then
    add_filter "fps=$FPS"
    mode=()
fi
[ -n "${CROP:-}" ] && add_filter "crop=$CROP"
add_filter "showinfo"
if [ -n "${TILE:-}" ]; then
    add_filter "scale=${WIDTH:-220}:-1"
    add_filter "tile=$TILE"
fi

ffmpeg -hide_banner -loglevel info -y ${cut[@]+"${cut[@]}"} -i "$video" -vf "$filters" \
    ${mode[@]+"${mode[@]}"} "$out/frames/%04d.png" 2> "$out/ffmpeg.log"
grep -o "pts_time:[0-9.]*" "$out/ffmpeg.log" | sed 's/pts_time://' | awk '{ printf "%04d %s\n", NR, $1 }' > "$out/times.txt"

echo "$video: $(wc -l < "$out/times.txt" | tr -d ' ') frames, $(find "$out/frames" -name '*.png' | wc -l | tr -d ' ') images in $out/frames"
exit "$status"
