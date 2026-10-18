import UIKit

/// Verification only, for scratch builds: reads and drives VoiceOver from inside the app, logging SOUSAX lines.
///
/// Darwin notifications ask for the work: `sous.axdump` logs the accessibility tree UIKit holds, `sous.axactivate`
/// activates the element VoiceOver is on, `sous.axescape` performs VoiceOver's escape.
@MainActor
enum AXDump {
    static func start() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        AXDump.dump()
                    }
                }
            },
            "sous.axdump" as CFString,
            nil,
            .deliverImmediately
        )
        // What a double tap does under VoiceOver, which nothing outside the simulator can perform.
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        AXDump.activate()
                    }
                }
            },
            "sous.axactivate" as CFString,
            nil,
            .deliverImmediately
        )
        // What VoiceOver's escape gesture (a two finger scrub) does: the first ancestor that takes it closes.
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        AXDump.escape()
                    }
                }
            },
            "sous.axescape" as CFString,
            nil,
            .deliverImmediately
        )
        logFocus()
        logAnnouncements()
    }

    private static func describe(_ object: NSObject?) -> String {
        guard let object else { return "nothing focused" }
        let traits = object.accessibilityTraits.rawValue
        let names = traitNames.filter({ traits & $0.0 != 0 }).map(\.1).joined(separator: "+")
        return "\"" + (object.accessibilityLabel ?? "") + "\" " + String(describing: type(of: object))
            + " value=" + (object.accessibilityValue.map({ "\"" + $0 + "\"" }) ?? "nil")
            + " traits=" + (names.isEmpty ? "none" : names)
    }

    private static func activate() {
        let focused = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? NSObject
        var done = focused?.accessibilityActivate() ?? false
        var how = "activate"
        // A bar's button does not activate itself: VoiceOver taps it, which this stands in for.
        if !done, let control = focused as? UIControl, control.isEnabled {
            control.sendActions(for: .touchUpInside)
            done = true
            how = "control"
        }
        NSLog("SOUSAX-ACTIVATE %@ done=%d how=%@", describe(focused), done ? 1 : 0, how)
    }

    private static func escape() {
        var object = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? NSObject
        var taker = "nobody"
        while let current = object {
            if current.accessibilityPerformEscape() {
                taker = String(describing: type(of: current))
                break
            }
            object = (current as? UIView)?.superview
                ?? ((current as? UIAccessibilityElement)?.accessibilityContainer as? NSObject)
                ?? (current.value(forKey: "accessibilityContainer") as? NSObject)
                ?? (current as? UIResponder)?.next
        }
        NSLog("SOUSAX-ESCAPE taken by %@", taker)
    }

    private static func logFocus() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.elementFocusedNotification,
            object: nil,
            queue: .main
        ) { note in
            let info = note.userInfo ?? [:]
            let focused = info[UIAccessibility.focusedElementUserInfoKey] as? NSObject
            let technology = info[UIAccessibility.assistiveTechnologyUserInfoKey] as? String
            NSLog(
                "SOUSAX-FOCUS %@ %@ tech=%@",
                focused?.accessibilityLabel.map({ "\"" + $0 + "\"" }) ?? "nil",
                focused.map({ String(describing: type(of: $0)) }) ?? "nothing",
                technology ?? "nil"
            )
        }
    }

    private static func logAnnouncements() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.announcementDidFinishNotification,
            object: nil,
            queue: .main
        ) { note in
            let info = note.userInfo ?? [:]
            let said = info[UIAccessibility.announcementStringValueUserInfoKey].map({ String(describing: $0) }) ?? "nil"
            let whole = (info[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool) ?? false
            NSLog("SOUSAX-ANNOUNCED \"%@\" whole=%d", said, whole ? 1 : 0)
        }
    }

    private static func dump() {
        let focused = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? NSObject
        NSLog(
            "SOUSAX-BEGIN voiceOver=%d focused=%@",
            UIAccessibility.isVoiceOverRunning ? 1 : 0,
            focused.map({ "\"" + ($0.accessibilityLabel ?? "") + "\" " + String(describing: type(of: $0)) }) ?? "nothing"
        )
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                walk(window, hidden: false)
            }
        }
        NSLog("SOUSAX-END")
    }

    private static let traitNames: [(UInt64, String)] = [
        (1 << 0, "button"), (1 << 1, "link"), (1 << 2, "image"), (1 << 3, "selected"), (1 << 6, "staticText"),
        (1 << 8, "notEnabled"), (1 << 9, "updatesFrequently"), (1 << 12, "adjustable"), (1 << 16, "header"),
        (1 << 18, "textEntry"), (1 << 21, "isEditing"), (1 << 53, "toggle")
    ]

    private static func walk(_ object: NSObject, hidden: Bool) {
        let view = object as? UIView
        let kind = String(describing: type(of: object))
        // A presented view controller's view sits in one of these, so a sheet's elements follow the last marker.
        if kind == "UIDropShadowView" {
            NSLog("SOUSAX-PRESENTATION modal=%d", (view?.accessibilityViewIsModal ?? false) ? 1 : 0)
        }
        let nowHidden = hidden || object.accessibilityElementsHidden || (view?.isHidden ?? false)
        if object.isAccessibilityElement {
            let frame = object.accessibilityFrame
            let traits = object.accessibilityTraits.rawValue
            let names = traitNames.filter({ traits & $0.0 != 0 }).map(\.1).joined(separator: "+")
            NSLog(
                "SOUSAX %@ label=%@ value=%@ hint=%@ traits=%@ (%llu) hidden=%d frame=%d,%d %dx%d",
                kind,
                object.accessibilityLabel.map({ "\"" + $0 + "\"" }) ?? "nil",
                object.accessibilityValue.map({ "\"" + $0 + "\"" }) ?? "nil",
                object.accessibilityHint.map({ "\"" + $0 + "\"" }) ?? "nil",
                names.isEmpty ? "none" : names,
                traits,
                nowHidden ? 1 : 0,
                Int(frame.minX), Int(frame.minY), Int(frame.width), Int(frame.height)
            )
            return
        }
        if let elements = object.accessibilityElements {
            for element in elements {
                if let child = element as? NSObject {
                    walk(child, hidden: nowHidden)
                }
            }
            return
        }
        let count = object.accessibilityElementCount()
        if count != NSNotFound, count > 0 {
            for index in 0..<count {
                if let child = object.accessibilityElement(at: index) as? NSObject {
                    walk(child, hidden: nowHidden)
                }
            }
            return
        }
        for subview in view?.subviews ?? [] {
            walk(subview, hidden: nowHidden)
        }
    }
}
