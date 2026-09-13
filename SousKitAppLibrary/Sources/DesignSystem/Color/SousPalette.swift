import SwiftUI

/// The raw colors: a neutral ramp read from both ends, and one orange in three values.
///
/// ``SousColor`` is the layer products draw from. Reach in here only for a value the semantic
/// layer has no token for, such as ``scorch`` and ``sear``.
public enum SousPalette {
    /// `#0F0F0F`, for body text on Paper, and for recessed wells on dark: inputs and code blocks.
    public static let ink = Color(hex: 0x0F0F0F)

    /// `#3A3A3A`, for long-form prose on Paper.
    public static let graphite = Color(hex: 0x3A3A3A)

    /// `#6B6B6B`, for secondary text on light, and for disabled and placeholder text on dark.
    public static let steel = Color(hex: 0x6B6B6B)

    /// `#A6A6A6`, for placeholders on light, and for secondary text and metadata on dark.
    public static let ash = Color(hex: 0xA6A6A6)

    /// `#E3E3E3`, the one border value on light grounds.
    public static let line = Color(hex: 0xE3E3E3)

    /// `#F6F6F6`, the light page ground, and the type color on dark.
    public static let paper = Color(hex: 0xF6F6F6)

    /// `#FFFFFF`, for light raised surfaces only. Retired on dark.
    public static let white = Color(hex: 0xFFFFFF)

    /// `#F1541C`, the signal value, for what is live, the current step, and the mark's middle
    /// curl. Carries dark text, never white.
    public static let flame = Color(hex: 0xF1541C)

    /// `#B83C0C`, for text on Paper, and as a fill only on dark.
    public static let ember = Color(hex: 0xB83C0C)

    /// `#FDEBE3`, an 8% Flame wash over Paper, for highlighted rows and callouts on light.
    public static let scorch = Color(hex: 0xFDEBE3)

    /// `#0A0A0A`, for what sits outside the frame on dark: browser chrome and letterboxing.
    public static let void = Color(hex: 0x0A0A0A)

    /// `#141414`, the dark page ground.
    public static let char = Color(hex: 0x141414)

    /// `#1C1C1C`, for dark raised surfaces, lifted by value and never by shadow.
    public static let pan = Color(hex: 0x1C1C1C)

    /// `#2E2E2E`, the one border value on dark grounds.
    public static let seam = Color(hex: 0x2E2E2E)

    /// `#8C8C8C`, for eyebrows, captions, and annotation on dark.
    public static let smoke = Color(hex: 0x8C8C8C)

    /// `#C9C9C9`, for long-form prose on dark.
    public static let chalk = Color(hex: 0xC9C9C9)

    /// `#2A1710`, a 12% Flame wash over Char, for highlighted rows and callouts on dark.
    public static let sear = Color(hex: 0x2A1710)
}
