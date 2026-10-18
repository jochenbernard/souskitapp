#!/bin/bash
# Swaps the stand-in timer scheduler into a scratch copy of the app's source, so timers run without AlarmKit.
# Usage: apply-standin-timers.sh <source dir>     (a `git archive` copy, never a worktree)
# Launch switches of the built app: SIMCTL_CHILD_SOUS_STANDIN_TIMERS=n seeds n timers,
# SIMCTL_CHILD_SOUS_STANDIN_LATE=s starts one more s seconds after the launch.
set -u

here=$(cd "$(dirname "$0")" && pwd)

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

source_dir=$(cd "$1" && pwd)
timers=$source_dir/SousKitAppLibrary/Sources/CookingFeature/Timers

if git -C "$source_dir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "$source_dir is a git checkout: the stand-in only goes into a git archive copy." >&2
    exit 1
fi

failed=0

# expect <file> <count> <text>: the file must hold the text on exactly that many lines.
expect() {
    found=$(grep -c -F -- "$3" "$timers/$1" 2> /dev/null)
    if [ "${found:-0}" -ne "$2" ]; then
        echo "CHANGED SHAPE: $1 holds \"$3\" ${found:-0} times, not $2" >&2
        failed=1
    fi
}

# What the stand-in replaces, and every declaration of the app it uses.
expect AlarmTimerScheduler.swift 1 "public struct AlarmTimerScheduler: TimerScheduler {"
expect AlarmTimerScheduler.swift 1 "    public init() {"
expect AlarmTimerScheduler.swift 4 "    public func "
expect TimerScheduler.swift 4 "    func "
expect TimerScheduler.swift 1 "    func currentRunningTimers() -> [RunningTimer]"
expect TimerScheduler.swift 1 "    func runningTimers() -> AsyncStream<[RunningTimer]>"
expect TimerScheduler.swift 1 "    func start(_ timer: CookingTimer) async throws"
expect TimerScheduler.swift 1 "    func cancel(_ timer: RunningTimer) throws"
expect RunningTimer.swift 4 "    public let "
expect RunningTimer.swift 1 "    public let id: UUID"
expect RunningTimer.swift 1 "    public let cookingTimer: CookingTimer"
expect RunningTimer.swift 1 "    public let endDate: Date"
expect RunningTimer.swift 1 "    public let isRinging: Bool"
expect CookingTimer.swift 1 "    case custom(Duration)"
expect CookingTimer.swift 1 "    var seconds: Double {"

if [ "$failed" -ne 0 ]; then
    echo "The app's timer code is no longer what $here/AlarmTimerScheduler.swift was written for: nothing changed. Update the stand-in and these checks together." >&2
    exit 1
fi

cp "$here/AlarmTimerScheduler.swift" "$timers/AlarmTimerScheduler.swift"
echo "stand-in timers in $timers/AlarmTimerScheduler.swift"
