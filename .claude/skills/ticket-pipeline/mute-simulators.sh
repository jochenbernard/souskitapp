#!/bin/sh
# Sends the sound of simulators to a silent virtual output device instead of the speakers.
# Usage: mute-simulators.sh <udid>...
# Each simulator must be shut down. `simctl erase` undoes it.
set -eu

if [ "$#" -eq 0 ]; then
    echo "usage: mute-simulators.sh <udid>..." >&2
    exit 64
fi

device=${SILENT_AUDIO_DEVICE_UID:-}

if [ -z "$device" ]; then
    device=$(xcrun swift - <<'EOF'
import CoreAudio

func address(
    _ selector: AudioObjectPropertySelector,
    _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func size(_ object: AudioObjectID, _ property: AudioObjectPropertyAddress) -> UInt32 {
    var property = property
    var size = UInt32(0)
    AudioObjectGetPropertyDataSize(object, &property, 0, nil, &size)
    return size
}

func string(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String {
    var property = address(selector)
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var result: Unmanaged<CFString>?
    guard AudioObjectGetPropertyData(object, &property, 0, nil, &size, &result) == noErr, let result else {
        return ""
    }
    return result.takeRetainedValue() as String
}

func transport(_ device: AudioObjectID) -> UInt32 {
    var property = address(kAudioDevicePropertyTransportType)
    var size = UInt32(MemoryLayout<UInt32>.size)
    var result = UInt32(0)
    AudioObjectGetPropertyData(device, &property, 0, nil, &size, &result)
    return result
}

// A device that a call or a recording may listen to comes last.
func rank(_ name: String) -> Int {
    if name.contains("BlackHole") {
        return 0
    }
    return name.contains("Teams") || name.contains("Microphone") ? 2 : 1
}

let system = AudioObjectID(kAudioObjectSystemObject)
var devicesProperty = address(kAudioHardwarePropertyDevices)
var devicesSize = size(system, devicesProperty)
var devices = [AudioObjectID](repeating: 0, count: Int(devicesSize) / MemoryLayout<AudioObjectID>.size)
AudioObjectGetPropertyData(system, &devicesProperty, 0, nil, &devicesSize, &devices)

let silent = devices
    .filter({ transport($0) == kAudioDeviceTransportTypeVirtual })
    .filter({ size($0, address(kAudioDevicePropertyStreams, kAudioObjectPropertyScopeOutput)) > 0 })
    .map({ (name: string($0, kAudioObjectPropertyName), uid: string($0, kAudioDevicePropertyDeviceUID)) })
    .sorted(by: { rank($0.name) < rank($1.name) })

if let device = silent.first {
    print(device.uid)
}
EOF
)
fi

if [ -z "$device" ]; then
    echo "No virtual output device to send the sound to. Install one (BlackHole) or set SILENT_AUDIO_DEVICE_UID." >&2
    exit 1
fi

for udid in "$@"; do
    if ! xcrun simctl list devices | grep -F "($udid)" | grep -q "(Shutdown)"; then
        echo "$udid is not a shut down simulator; shut it down first." >&2
        exit 1
    fi

    run="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/var/run"
    settings="$run/com.apple.coresimulator.audio.plist"

    # The first boot throws away a file that lacks any of the four keys.
    if [ ! -f "$settings" ]; then
        mkdir -p "$run"
        plutil -create xml1 "$settings"
        plutil -replace sim_input_device_uid -string BuiltInMicrophoneDevice "$settings"
        plutil -replace useHostDefaultInputDevice -bool true "$settings"
    fi

    plutil -replace useHostDefaultOutputDevice -bool false "$settings"
    plutil -replace sim_output_device_uid -string "$device" "$settings"
    echo "$udid sends its sound to $device"
done
