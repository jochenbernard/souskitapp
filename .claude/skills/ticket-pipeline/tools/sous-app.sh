#!/bin/bash
# The Sous app's own navigation, the only script here that knows its screens: runs steps through the app.
# Usage: sous-app.sh <udid> <en|nl-BE> <step>...
#   mock             onboarding's mock recipes, on a fresh install
#   recipe:<name>    a recipe in the kitchen's list, such as "recipe:quiche lorraine"
#   back             from a recipe to the kitchen (mock recipes only)
#   cook             the recipe's start cooking button
#   timer:<label>    a step's timer link on the cooking screen, such as "timer:30 min"
#   new-timer        opens the cooking screen's new timer sheet; cancel closes it
#   scale            opens the recipe's scale sheet; done closes it
#   settings         the kitchen's settings; done closes them
#   stop             leaves the cooking screen and confirms, which cancels every timer
# The app must be launched in the same language. OFFX and OFFY pass through to tap.sh for an iPad window.
set -u

here=$(cd "$(dirname "$0")" && pwd)

if [ "$#" -lt 3 ]; then
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 64
fi

udid=$1
language=$2
shift 2

case $language in
en)
    mock='Use mock recipes'; kitchen='Mock recipes'; cook='Start cooking'; new_timer='New timer'; scale='^Scale,'
    settings='Settings'; close='Close'; stop='Stop cooking'; cancel='Cancel'; done_='Done'
    ;;
nl-BE)
    mock='Testrecepten gebruiken'; kitchen='Testrecepten'; cook='Beginnen met koken'; new_timer='Nieuwe timer'
    scale='^Omrekenen,'; settings='Instellingen'; close='Sluit'; stop='Stoppen met koken'; cancel='Annuleer'
    done_='Gereed'
    ;;
*)
    echo "unknown language $language" >&2
    exit 64
    ;;
esac

# tap <label> [seconds to settle]
tap() {
    WAIT=10 "$here/tap.sh" "$udid" "$1" || exit 1
    sleep "${2:-2.5}"
}

for step in "$@"; do
    case $step in
    mock) tap "$mock" ;;
    recipe:*) tap "${step#recipe:}" ;;
    back) tap "$kitchen" ;;
    cook) tap "$cook" 3 ;;
    timer:*) tap "${step#timer:}" ;;
    new-timer) tap "$new_timer" 3 ;;
    scale) tap "$scale" 3 ;;
    settings) tap "$settings" 3 ;;
    cancel) tap "$cancel" ;;
    done) tap "$done_" ;;
    stop)
        tap "$close" 1.5
        tap "$stop"
        ;;
    *)
        echo "unknown step $step" >&2
        exit 64
        ;;
    esac
done
