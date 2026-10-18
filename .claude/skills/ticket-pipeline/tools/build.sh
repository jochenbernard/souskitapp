#!/bin/bash
# Builds, tests and lints a source folder of the app the way the pipeline does.
# Usage: build.sh build <source dir> <derived data dir>            prints the .app path
#        build.sh test  <source dir> <derived data dir> <udid>     every test target, on a muted simulator
#        build.sh lint  <source dir> <file>...                     swiftlint --strict on the given files
# The full xcodebuild output lands in <derived data dir>/build.log or test.log.
set -u

here=$(cd "$(dirname "$0")" && pwd)

usage() {
    sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
}

[ "$#" -ge 2 ] || usage
command=$1
source_dir=$(cd "$2" 2> /dev/null && pwd) || { echo "no source folder $2" >&2; exit 1; }
shift 2

case $command in
build)
    [ "$#" -eq 1 ] || usage
    mkdir -p "$1"
    derived=$(cd "$1" && pwd)
    log=$derived/build.log

    (cd "$source_dir" && xcodebuild build \
        -project SousKitApp.xcodeproj \
        -scheme SousKitApp \
        -configuration Debug \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "$derived" \
        -skipPackagePluginValidation \
        -skipMacroValidation) > "$log" 2>&1
    status=$?

    app=$derived/Build/Products/Debug-iphonesimulator/SousKitApp.app
    if [ "$status" -ne 0 ] || [ ! -d "$app" ]; then
        grep -E "error:|FAILED" "$log" | sort -u | head -40 >&2
        echo "build failed (exit $status), see $log" >&2
        exit 1
    fi
    grep -E "warning: .*(SousKitAppLibrary|Sources/)" "$log" | sort -u | head -20 >&2
    echo "$app"
    ;;

test)
    [ "$#" -eq 2 ] || usage
    mkdir -p "$1"
    derived=$(cd "$1" && pwd)
    udid=$2
    log=$derived/test.log
    resolved=$source_dir/SousKitAppLibrary/Package.resolved
    had_resolved=no
    [ -e "$resolved" ] && had_resolved=yes

    # xcodebuild boots the simulator itself, so it is booted here first, which refuses an unmuted one.
    "$here/sim.sh" "$udid" boot || exit 1

    (cd "$source_dir/SousKitAppLibrary" && xcodebuild test \
        -scheme SousKitAppLibrary \
        -destination "platform=iOS Simulator,id=$udid" \
        -derivedDataPath "$derived" \
        -skipPackagePluginValidation \
        -skipMacroValidation) > "$log" 2>&1
    status=$?

    # The run writes a Package.resolved the repository does not hold.
    [ "$had_resolved" = no ] && rm -f "$resolved"

    grep -E "error:|✘|with [0-9]+ issue|Test run with|TEST SUCCEEDED|TEST FAILED" "$log" | sort -u | tail -30
    if [ "$status" -ne 0 ] || ! grep -q "TEST SUCCEEDED" "$log"; then
        echo "tests failed (exit $status), see $log" >&2
        exit 1
    fi
    ;;

lint)
    [ "$#" -ge 1 ] || usage
    # Run from the source folder, whose .swiftlint.yml holds the rules; relative paths are relative to it.
    files=()
    for file in "$@"; do
        case $file in
        /*) files+=("$file") ;;
        *) files+=("$source_dir/$file") ;;
        esac
    done
    (cd "$source_dir" && swiftlint lint --strict "${files[@]}")
    ;;

*)
    usage
    ;;
esac
